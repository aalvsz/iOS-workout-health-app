import Foundation

class RecoveryAnalyzer {
    static let shared = RecoveryAnalyzer()

    // Rolling window for baseline calculations
    private let baselineWindowDays = 28

    // Z-score thresholds for flagging
    private let hrvLowThreshold = -1.5
    private let hrHighThreshold = 1.5
    private let sleepLowThreshold = -1.0

    // Anomaly detection threshold
    private let anomalyThreshold = 2.0

    private init() {}

    // MARK: - Recovery Analysis
    func analyzeRecovery(
        today: DailyHealthSummary,
        historicalData: [DailyHealthSummary]
    ) -> RecoveryAnalysis {
        guard historicalData.count >= 7 else {
            // Not enough data for meaningful analysis
            return RecoveryAnalysis(
                date: today.date,
                status: .moderate,
                score: 70,
                hrvDeviation: 0,
                heartRateDeviation: 0,
                sleepDeviation: 0,
                factors: [],
                isAnomaly: false
            )
        }

        // Calculate baseline statistics
        let baseline = calculateBaseline(from: historicalData)

        // Calculate z-scores for today
        let hrvZ = baseline.hrvStd > 0 ? (today.hrvMs - baseline.hrvMean) / baseline.hrvStd : 0
        let hrZ = baseline.hrStd > 0 ? (today.restingHeartRate - baseline.hrMean) / baseline.hrStd : 0
        let sleepZ = baseline.sleepStd > 0 ? (today.sleepHours - baseline.sleepMean) / baseline.sleepStd : 0

        // Build recovery factors
        var factors: [RecoveryFactor] = []

        factors.append(RecoveryFactor(
            name: "HRV",
            value: today.hrvMs,
            deviation: hrvZ,
            impact: hrvZ > 0.5 ? .positive : (hrvZ < -0.5 ? .negative : .neutral)
        ))

        factors.append(RecoveryFactor(
            name: "Resting HR",
            value: today.restingHeartRate,
            deviation: hrZ,
            impact: hrZ < -0.5 ? .positive : (hrZ > 0.5 ? .negative : .neutral)
        ))

        factors.append(RecoveryFactor(
            name: "Sleep",
            value: today.sleepHours,
            deviation: sleepZ,
            impact: sleepZ > 0.5 ? .positive : (sleepZ < -0.5 ? .negative : .neutral)
        ))

        // Calculate composite recovery score
        let score = calculateRecoveryScore(hrvZ: hrvZ, hrZ: hrZ, sleepZ: sleepZ)

        // Determine recovery status
        let status = determineRecoveryStatus(score: score)

        // Check for anomalies
        let isAnomaly = detectAnomaly(today: today, baseline: baseline)
        let anomalyReason = isAnomaly ? summarizeAnomalyReason(today: today, baseline: baseline) : nil

        return RecoveryAnalysis(
            date: today.date,
            status: status,
            score: score,
            hrvDeviation: hrvZ,
            heartRateDeviation: hrZ,
            sleepDeviation: sleepZ,
            factors: factors,
            isAnomaly: isAnomaly,
            anomalyReason: anomalyReason
        )
    }

    // MARK: - Batch Analysis
    func analyzeRecoveryTrend(data: [DailyHealthSummary]) -> [RecoveryAnalysis] {
        var analyses: [RecoveryAnalysis] = []

        for (index, day) in data.enumerated() {
            let historicalData = Array(data.prefix(index))
            let analysis = analyzeRecovery(today: day, historicalData: historicalData)
            analyses.append(analysis)
        }

        return analyses
    }

    // MARK: - Recovery Flags
    func buildRecoveryFlags(data: [DailyHealthSummary]) -> [RecoveryFlag] {
        var flags: [RecoveryFlag] = []

        guard data.count >= baselineWindowDays else { return flags }

        for i in baselineWindowDays..<data.count {
            let window = Array(data[(i - baselineWindowDays)..<i])
            let today = data[i]

            let baseline = calculateBaseline(from: window)

            // Check HRV (low HRV = stress)
            if baseline.hrvStd > 0 {
                let hrvZ = (today.hrvMs - baseline.hrvMean) / baseline.hrvStd
                if hrvZ < hrvLowThreshold {
                    flags.append(RecoveryFlag(
                        date: today.date,
                        type: .lowHRV,
                        severity: abs(hrvZ) > 2 ? .high : .medium,
                        value: today.hrvMs,
                        baseline: baseline.hrvMean,
                        deviation: hrvZ
                    ))
                }
            }

            // Check Resting HR (high HR = fatigue/stress)
            if baseline.hrStd > 0 {
                let hrZ = (today.restingHeartRate - baseline.hrMean) / baseline.hrStd
                if hrZ > hrHighThreshold {
                    flags.append(RecoveryFlag(
                        date: today.date,
                        type: .elevatedHR,
                        severity: abs(hrZ) > 2 ? .high : .medium,
                        value: today.restingHeartRate,
                        baseline: baseline.hrMean,
                        deviation: hrZ
                    ))
                }
            }

            // Check Sleep (low sleep = recovery concern)
            if baseline.sleepStd > 0 {
                let sleepZ = (today.sleepHours - baseline.sleepMean) / baseline.sleepStd
                if sleepZ < sleepLowThreshold {
                    flags.append(RecoveryFlag(
                        date: today.date,
                        type: .lowSleep,
                        severity: abs(sleepZ) > 2 ? .high : .medium,
                        value: today.sleepHours,
                        baseline: baseline.sleepMean,
                        deviation: sleepZ
                    ))
                }
            }
        }

        return flags
    }

    // MARK: - Private Helpers
    private func calculateBaseline(from data: [DailyHealthSummary]) -> BaselineStats {
        let recentData = data.suffix(baselineWindowDays)

        let hrvValues = recentData.map(\.hrvMs).filter { $0 > 0 }
        let hrValues = recentData.map(\.restingHeartRate).filter { $0 > 0 }
        let sleepValues = recentData.map(\.sleepHours).filter { $0 > 0 }
        let stepsValues = recentData.map { Double($0.steps) }
        let workoutValues = recentData.map(\.workoutMinutes)

        return BaselineStats(
            hrvMean: mean(hrvValues),
            hrvStd: std(hrvValues),
            hrMean: mean(hrValues),
            hrStd: std(hrValues),
            sleepMean: mean(sleepValues),
            sleepStd: std(sleepValues),
            stepsMean: mean(stepsValues),
            stepsStd: std(stepsValues),
            workoutMean: mean(workoutValues),
            workoutStd: std(workoutValues)
        )
    }

    private func calculateRecoveryScore(hrvZ: Double, hrZ: Double, sleepZ: Double) -> Double {
        // Higher HRV is good, lower HR is good, higher sleep is good
        // Normalize to 0-100 scale
        let hrvScore = normalize(hrvZ, goodDirection: .positive)
        let hrScore = normalize(-hrZ, goodDirection: .positive) // Flip HR (lower is better)
        let sleepScore = normalize(sleepZ, goodDirection: .positive)

        // Weighted average (HRV is most important for recovery)
        let weightedScore = (hrvScore * 0.4 + hrScore * 0.3 + sleepScore * 0.3)

        return max(0, min(100, weightedScore))
    }

    private func normalize(_ zScore: Double, goodDirection: Direction) -> Double {
        // Convert z-score to 0-100 scale
        // z = 0 -> 70 (baseline)
        // z = 2 -> 100 (excellent) or 40 (poor)
        // z = -2 -> 40 (poor) or 100 (excellent)

        let base = 70.0
        let adjustment = zScore * 15 // Each std dev = 15 points

        switch goodDirection {
        case .positive:
            return base + adjustment
        case .negative:
            return base - adjustment
        }
    }

    private enum Direction {
        case positive
        case negative
    }

    private func determineRecoveryStatus(score: Double) -> RecoveryStatus {
        switch score {
        case 85...:
            return .optimal
        case 70..<85:
            return .good
        case 55..<70:
            return .moderate
        case 40..<55:
            return .needsRest
        default:
            return .critical
        }
    }

    private func detectAnomaly(today: DailyHealthSummary, baseline: BaselineStats) -> Bool {
        let features = [
            (today.sleepHours, baseline.sleepMean, baseline.sleepStd),
            (today.hrvMs, baseline.hrvMean, baseline.hrvStd),
            (today.restingHeartRate, baseline.hrMean, baseline.hrStd),
            (Double(today.steps), baseline.stepsMean, baseline.stepsStd),
            (today.workoutMinutes, baseline.workoutMean, baseline.workoutStd)
        ]

        // Count how many features are beyond the anomaly threshold
        var anomalyCount = 0
        for (value, mean, std) in features {
            if std > 0 && value > 0 {
                let z = abs((value - mean) / std)
                if z > anomalyThreshold {
                    anomalyCount += 1
                }
            }
        }

        // If 2 or more features are anomalous, flag it
        return anomalyCount >= 2
    }

    private func summarizeAnomalyReason(today: DailyHealthSummary, baseline: BaselineStats) -> String {
        var reasons: [String] = []

        let features: [(String, Double, Double, Double, Bool)] = [
            ("sleep", today.sleepHours, baseline.sleepMean, baseline.sleepStd, true),
            ("HRV", today.hrvMs, baseline.hrvMean, baseline.hrvStd, true),
            ("resting HR", today.restingHeartRate, baseline.hrMean, baseline.hrStd, false),
            ("steps", Double(today.steps), baseline.stepsMean, baseline.stepsStd, true),
            ("workout time", today.workoutMinutes, baseline.workoutMean, baseline.workoutStd, true)
        ]

        for (name, value, meanVal, std, higherIsBetter) in features {
            if std > 0 && value > 0 {
                let z = (value - meanVal) / std
                if abs(z) > 1.5 {
                    if z > 0 {
                        reasons.append(higherIsBetter ? "\(name) high" : "\(name) elevated")
                    } else {
                        reasons.append(higherIsBetter ? "\(name) low" : "\(name) low")
                    }
                }
            }
        }

        return reasons.prefix(2).joined(separator: ", ")
    }

    private func mean(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private func std(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let meanValue = mean(values)
        let variance = values.reduce(0) { $0 + pow($1 - meanValue, 2) } / Double(values.count - 1)
        return sqrt(variance)
    }
}

// MARK: - Supporting Types
struct BaselineStats {
    let hrvMean: Double
    let hrvStd: Double
    let hrMean: Double
    let hrStd: Double
    let sleepMean: Double
    let sleepStd: Double
    let stepsMean: Double
    let stepsStd: Double
    let workoutMean: Double
    let workoutStd: Double
}

struct RecoveryFlag: Identifiable {
    let id = UUID()
    let date: Date
    let type: FlagType
    let severity: Severity
    let value: Double
    let baseline: Double
    let deviation: Double

    enum FlagType: String {
        case lowHRV = "Low HRV"
        case elevatedHR = "Elevated Heart Rate"
        case lowSleep = "Insufficient Sleep"
        case overtraining = "Overtraining Risk"
        case underRecovery = "Under-Recovery"

        var icon: String {
            switch self {
            case .lowHRV: return "waveform.path.ecg"
            case .elevatedHR: return "heart.fill"
            case .lowSleep: return "bed.double.fill"
            case .overtraining: return "exclamationmark.triangle.fill"
            case .underRecovery: return "battery.25"
            }
        }

        var recommendation: String {
            switch self {
            case .lowHRV:
                return "Consider light activity and stress management today."
            case .elevatedHR:
                return "Your body may be fighting something. Prioritize rest."
            case .lowSleep:
                return "Aim for an earlier bedtime tonight."
            case .overtraining:
                return "Take a rest day or do very light activity."
            case .underRecovery:
                return "Focus on sleep, nutrition, and hydration."
            }
        }
    }

    enum Severity {
        case low
        case medium
        case high

        var color: String {
            switch self {
            case .low: return "severityLow"
            case .medium: return "severityMedium"
            case .high: return "severityHigh"
            }
        }
    }
}

// MARK: - Insights Generation
extension RecoveryAnalyzer {
    func generateInsights(
        analyses: [RecoveryAnalysis],
        profile: UserProfile
    ) -> [Insight] {
        var insights: [Insight] = []

        guard let latest = analyses.last else { return insights }

        // Recovery status insight
        insights.append(Insight(
            title: "Recovery: \(latest.status.rawValue)",
            description: latest.status.recommendation,
            type: .recovery,
            priority: latest.status == .critical ? .critical : (latest.status == .needsRest ? .high : .medium),
            actionable: latest.status != .optimal,
            action: latest.status == .needsRest || latest.status == .critical ? "Take a rest day" : nil
        ))

        // Trend analysis
        if analyses.count >= 7 {
            let recentScores = analyses.suffix(7).map(\.score)
            let trend = calculateTrend(recentScores)

            if trend < -5 {
                insights.append(Insight(
                    title: "Recovery Declining",
                    description: "Your recovery scores have been trending downward. Consider reducing training intensity.",
                    type: .trend,
                    priority: .high,
                    actionable: true,
                    action: "Review training load"
                ))
            } else if trend > 5 {
                insights.append(Insight(
                    title: "Recovery Improving",
                    description: "Great job! Your recovery is trending upward. You're ready to push harder if desired.",
                    type: .trend,
                    priority: .low
                ))
            }
        }

        // Anomaly insight
        if latest.isAnomaly, let reason = latest.anomalyReason {
            insights.append(Insight(
                title: "Unusual Pattern Detected",
                description: "Today's data shows unusual values: \(reason). This could indicate stress or illness.",
                type: .anomaly,
                priority: .high,
                actionable: true,
                action: "Monitor symptoms"
            ))
        }

        // Sleep insight
        if latest.sleepDeviation < -1 {
            insights.append(Insight(
                title: "Sleep Debt",
                description: "You're sleeping less than your baseline. Prioritize sleep for better recovery.",
                type: .sleep,
                priority: .medium,
                actionable: true,
                action: "Aim for 8 hours tonight"
            ))
        }

        return insights.sorted { $0.priority > $1.priority }
    }

    private func calculateTrend(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return 0 }

        let n = Double(values.count)
        let xMean = (n - 1) / 2
        let yMean = values.reduce(0, +) / n

        var numerator = 0.0
        var denominator = 0.0

        for (i, y) in values.enumerated() {
            let x = Double(i)
            numerator += (x - xMean) * (y - yMean)
            denominator += pow(x - xMean, 2)
        }

        guard denominator != 0 else { return 0 }
        return numerator / denominator
    }
}
