import Foundation

class GoalPredictionService {
    static let shared = GoalPredictionService()

    private let persistence = PersistenceController.shared

    private init() {}

    // MARK: - Calculate Prediction

    func calculateWeightPrediction(
        profile: UserProfile,
        weightHistory: [WeightEntry]
    ) -> GoalPrediction? {
        guard weightHistory.count >= 3 else { return nil }

        let sortedHistory = weightHistory.sorted { $0.date < $1.date }
        let currentWeight = sortedHistory.last?.weightKg ?? profile.weightKg
        let targetWeight = profile.targetWeightKg ?? currentWeight

        // Calculate weekly change rate
        let weeklyChange = calculateWeeklyChangeRate(from: sortedHistory)
        let trendDirection = determineTrend(weeklyChange: weeklyChange, goal: profile.fitnessGoal)

        // Predict completion date
        let predictedDate = predictCompletionDate(
            currentWeight: currentWeight,
            targetWeight: targetWeight,
            weeklyChange: weeklyChange,
            goal: profile.fitnessGoal
        )

        // Calculate confidence based on data consistency
        let confidence = calculateConfidence(from: sortedHistory)

        let goalType: GoalType
        switch profile.fitnessGoal {
        case .loseWeight:
            goalType = .weightLoss
        case .gainMuscle:
            goalType = .weightGain
        case .maintain:
            goalType = .maintenance
        default:
            goalType = .fitness
        }

        let prediction = GoalPrediction(
            goalType: goalType,
            currentValue: currentWeight,
            targetValue: targetWeight,
            unit: "kg",
            predictedCompletionDate: predictedDate,
            trendDirection: trendDirection,
            weeklyChange: weeklyChange,
            confidenceLevel: confidence,
            lastUpdated: Date()
        )

        // Save prediction
        persistence.saveGoalPrediction(prediction)

        return prediction
    }

    // MARK: - Get Current Prediction

    func getCurrentPrediction(for goalType: GoalType) -> GoalPrediction? {
        persistence.getGoalPrediction(for: goalType)
    }

    func getAllPredictions() -> [GoalPrediction] {
        persistence.loadGoalPredictions()
    }

    // MARK: - Refresh Prediction

    func refreshPrediction(profile: UserProfile) -> GoalPrediction? {
        let weightHistory = persistence.loadWeightHistory()
        return calculateWeightPrediction(profile: profile, weightHistory: weightHistory)
    }

    // MARK: - Private Calculations

    private func calculateWeeklyChangeRate(from history: [WeightEntry]) -> Double {
        guard history.count >= 2 else { return 0 }

        // Use last 4 weeks of data if available
        let fourWeeksAgo = Calendar.current.date(byAdding: .day, value: -28, to: Date()) ?? Date()
        let recentHistory = history.filter { $0.date >= fourWeeksAgo }

        guard recentHistory.count >= 2,
              let first = recentHistory.first,
              let last = recentHistory.last else {
            return 0
        }

        let weightChange = last.weightKg - first.weightKg
        let daysDiff = Calendar.current.dateComponents([.day], from: first.date, to: last.date).day ?? 1
        let weeksDiff = max(1.0, Double(daysDiff) / 7.0)

        return weightChange / weeksDiff
    }

    private func determineTrend(weeklyChange: Double, goal: UserProfile.FitnessGoal) -> TrendDirection {
        let threshold = 0.1 // kg per week

        switch goal {
        case .loseWeight:
            if weeklyChange < -threshold {
                return .improving
            } else if weeklyChange > threshold {
                return .declining
            }
            return .steady

        case .gainMuscle:
            if weeklyChange > threshold {
                return .improving
            } else if weeklyChange < -threshold {
                return .declining
            }
            return .steady

        default:
            if abs(weeklyChange) < threshold {
                return .steady
            }
            return weeklyChange > 0 ? .improving : .declining
        }
    }

    private func predictCompletionDate(
        currentWeight: Double,
        targetWeight: Double,
        weeklyChange: Double,
        goal: UserProfile.FitnessGoal
    ) -> Date? {
        let weightDiff = targetWeight - currentWeight

        // Check if already at goal
        if abs(weightDiff) < 0.5 {
            return Date() // Already at goal
        }

        // Check if moving in wrong direction
        switch goal {
        case .loseWeight:
            if weeklyChange >= 0 {
                return nil // Not losing weight
            }
        case .gainMuscle:
            if weeklyChange <= 0 {
                return nil // Not gaining weight
            }
        default:
            break
        }

        guard abs(weeklyChange) > 0.01 else { return nil }

        let weeksToGoal = abs(weightDiff / weeklyChange)

        // Cap at 2 years
        guard weeksToGoal <= 104 else { return nil }

        return Calendar.current.date(byAdding: .weekOfYear, value: Int(weeksToGoal), to: Date())
    }

    private func calculateConfidence(from history: [WeightEntry]) -> Double {
        guard history.count >= 3 else { return 0.3 }

        // More data = higher confidence (capped at 0.9)
        let dataConfidence = min(0.4, Double(history.count) * 0.02)

        // Consistency of measurements (how regular are the entries)
        let consistencyConfidence = calculateMeasurementConsistency(from: history)

        // Trend stability (are measurements moving in consistent direction)
        let stabilityConfidence = calculateTrendStability(from: history)

        return min(0.95, dataConfidence + consistencyConfidence + stabilityConfidence)
    }

    private func calculateMeasurementConsistency(from history: [WeightEntry]) -> Double {
        guard history.count >= 2 else { return 0.1 }

        let sortedHistory = history.sorted { $0.date < $1.date }
        var intervals: [Int] = []

        for i in 1..<sortedHistory.count {
            let days = Calendar.current.dateComponents(
                [.day],
                from: sortedHistory[i-1].date,
                to: sortedHistory[i].date
            ).day ?? 0
            intervals.append(days)
        }

        guard !intervals.isEmpty else { return 0.1 }

        let avgInterval = Double(intervals.reduce(0, +)) / Double(intervals.count)

        // Ideal is daily or weekly (1-7 days)
        if avgInterval <= 7 {
            return 0.3
        } else if avgInterval <= 14 {
            return 0.2
        }
        return 0.1
    }

    private func calculateTrendStability(from history: [WeightEntry]) -> Double {
        guard history.count >= 3 else { return 0.1 }

        let sortedHistory = history.sorted { $0.date < $1.date }
        var changes: [Double] = []

        for i in 1..<sortedHistory.count {
            changes.append(sortedHistory[i].weightKg - sortedHistory[i-1].weightKg)
        }

        guard !changes.isEmpty else { return 0.1 }

        // Count direction changes (lower = more stable)
        var directionChanges = 0
        for i in 1..<changes.count {
            if (changes[i] > 0 && changes[i-1] < 0) || (changes[i] < 0 && changes[i-1] > 0) {
                directionChanges += 1
            }
        }

        let changeRatio = Double(directionChanges) / Double(changes.count)

        // Fewer direction changes = higher stability
        return 0.3 * (1 - changeRatio)
    }

    // MARK: - Prediction Summary

    func getPredictionSummary(profile: UserProfile) -> PredictionSummary {
        let prediction = refreshPrediction(profile: profile)
        let weightHistory = persistence.loadWeightHistory()

        let recentEntries = weightHistory.suffix(7).map { $0 }
        let avgWeight = recentEntries.isEmpty ? profile.weightKg :
            recentEntries.reduce(0) { $0 + $1.weightKg } / Double(recentEntries.count)

        return PredictionSummary(
            prediction: prediction,
            currentWeight: avgWeight,
            targetWeight: profile.targetWeightKg ?? avgWeight,
            recentWeightEntries: recentEntries,
            hasEnoughData: weightHistory.count >= 3
        )
    }
}

// MARK: - Prediction Summary

struct PredictionSummary {
    let prediction: GoalPrediction?
    let currentWeight: Double
    let targetWeight: Double
    let recentWeightEntries: [WeightEntry]
    let hasEnoughData: Bool

    var weightRemaining: Double {
        abs(targetWeight - currentWeight)
    }

    var isOnTrack: Bool {
        prediction?.isOnTrack ?? false
    }

    var formattedWeightRemaining: String {
        String(format: "%.1f kg", weightRemaining)
    }

    var message: String {
        guard let prediction = prediction else {
            if !hasEnoughData {
                return "Log more weight entries to see your progress prediction."
            }
            return "Keep logging to see your predicted goal date."
        }

        if let date = prediction.formattedPrediction {
            switch prediction.trendDirection {
            case .improving:
                return "On track to reach your goal by \(date)"
            case .steady:
                return "Progress is steady. Stay consistent!"
            case .declining:
                return "Progress has slowed. Time to refocus!"
            }
        }

        return "Keep going! Every step counts."
    }
}
