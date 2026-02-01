import Foundation

class HealthDataParser {
    static let shared = HealthDataParser()

    private init() {}

    // MARK: - Parsed Data Cache
    private var cachedWorkouts: [GymWorkout]?
    private var cachedBodyMetrics: BodyMetrics?

    // MARK: - Parse Export File
    func parseExportFile(at path: String) async throws -> ParsedHealthData {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)

        // Parse XML in background
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let parser = HealthXMLParser(data: data)
                    let result = try parser.parse()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Get Gym Workouts
    func getGymWorkouts() -> [GymWorkout] {
        if let cached = cachedWorkouts {
            return cached
        }

        // Try to load from bundled/parsed data
        let workouts = loadParsedWorkouts()
        cachedWorkouts = workouts
        return workouts
    }

    private func loadParsedWorkouts() -> [GymWorkout] {
        // Load pre-parsed workout data
        guard let url = Bundle.main.url(forResource: "workouts", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let workouts = try? JSONDecoder().decode([GymWorkout].self, from: data) else {
            return generateSampleWorkouts()
        }
        return workouts
    }

    // MARK: - Sample Data (when no export available)
    func generateSampleWorkouts() -> [GymWorkout] {
        var workouts: [GymWorkout] = []
        let calendar = Calendar.current

        // Generate realistic gym workout history
        let workoutTypes: [(String, [String])] = [
            ("Push Day", ["Bench Press", "Overhead Press", "Incline Dumbbell Press", "Tricep Pushdown", "Lateral Raises"]),
            ("Pull Day", ["Deadlift", "Barbell Row", "Pull-ups", "Face Pulls", "Bicep Curls"]),
            ("Leg Day", ["Squat", "Romanian Deadlift", "Leg Press", "Leg Curl", "Calf Raises"]),
            ("Upper Body", ["Bench Press", "Barbell Row", "Overhead Press", "Pull-ups", "Dips"]),
            ("Full Body", ["Squat", "Bench Press", "Deadlift", "Pull-ups", "Overhead Press"])
        ]

        for weeksAgo in 0..<12 {
            // 3-5 workouts per week
            let workoutsThisWeek = Int.random(in: 3...5)
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: Date())!

            for dayOffset in [0, 1, 3, 4, 5].prefix(workoutsThisWeek) {
                guard let workoutDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }

                let typeIndex = (weeksAgo * 3 + dayOffset) % workoutTypes.count
                let (name, exercises) = workoutTypes[typeIndex]

                let duration = Double.random(in: 55...95)
                let calories = duration * Double.random(in: 6...9)

                let workout = GymWorkout(
                    id: UUID(),
                    date: workoutDate,
                    name: name,
                    duration: duration,
                    calories: calories,
                    exercises: exercises.map { exerciseName in
                        Exercise(
                            name: exerciseName,
                            sets: generateSets(for: exerciseName)
                        )
                    },
                    averageHeartRate: Double.random(in: 110...145),
                    notes: nil
                )
                workouts.append(workout)
            }
        }

        return workouts.sorted { $0.date > $1.date }
    }

    private func generateSets(for exercise: String) -> [ExerciseSet] {
        let setCount = Int.random(in: 3...5)
        var sets: [ExerciseSet] = []

        // Base weights for different exercises
        let baseWeight: Double
        let baseReps: Int

        switch exercise {
        case "Squat": baseWeight = 80; baseReps = 8
        case "Deadlift": baseWeight = 100; baseReps = 5
        case "Bench Press": baseWeight = 60; baseReps = 8
        case "Overhead Press": baseWeight = 40; baseReps = 8
        case "Barbell Row": baseWeight = 50; baseReps = 10
        case "Romanian Deadlift": baseWeight = 70; baseReps = 10
        case "Leg Press": baseWeight = 120; baseReps = 12
        case "Pull-ups": baseWeight = 0; baseReps = 8
        default: baseWeight = 20; baseReps = 12
        }

        for i in 0..<setCount {
            let weight = baseWeight + Double(i) * 5
            let reps = max(baseReps - i, 5)
            sets.append(ExerciseSet(
                setNumber: i + 1,
                weight: weight,
                reps: reps,
                isWarmup: i == 0 && baseWeight > 50
            ))
        }

        return sets
    }
}

// MARK: - XML Parser
class HealthXMLParser: NSObject, XMLParserDelegate {
    private let data: Data
    private var workouts: [GymWorkout] = []
    private var bodyMetrics: BodyMetrics?

    private var currentElement = ""
    private var currentWorkout: WorkoutBuilder?
    private var latestWeight: Double?
    private var latestHeight: Double?

    init(data: Data) {
        self.data = data
    }

    func parse() throws -> ParsedHealthData {
        let parser = XMLParser(data: data)
        parser.delegate = self

        if parser.parse() {
            return ParsedHealthData(
                workouts: workouts,
                bodyMetrics: BodyMetrics(
                    weight: latestWeight ?? 75,
                    height: latestHeight ?? 175
                )
            )
        } else if let error = parser.parserError {
            throw error
        } else {
            throw NSError(domain: "HealthParser", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown parsing error"])
        }
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName

        if elementName == "Workout" {
            let activityType = attributeDict["workoutActivityType"] ?? ""

            // Only parse strength training workouts
            if activityType.contains("StrengthTraining") || activityType.contains("TraditionalStrength") {
                currentWorkout = WorkoutBuilder()
                currentWorkout?.activityType = activityType

                if let duration = attributeDict["duration"], let durationValue = Double(duration) {
                    currentWorkout?.duration = durationValue
                }

                if let startDate = attributeDict["startDate"] {
                    currentWorkout?.date = parseDate(startDate)
                }
            }
        }

        if elementName == "Record" {
            let type = attributeDict["type"] ?? ""

            if type == "HKQuantityTypeIdentifierBodyMass" {
                if let value = attributeDict["value"], let weight = Double(value) {
                    latestWeight = weight
                }
            }

            if type == "HKQuantityTypeIdentifierHeight" {
                if let value = attributeDict["value"], let height = Double(value) {
                    latestHeight = height * 100 // Convert to cm if in meters
                }
            }
        }

        if elementName == "WorkoutStatistics", currentWorkout != nil {
            let type = attributeDict["type"] ?? ""
            if type.contains("ActiveEnergyBurned") {
                if let sum = attributeDict["sum"], let calories = Double(sum) {
                    currentWorkout?.calories = calories
                }
            }
            if type.contains("HeartRate") {
                if let avg = attributeDict["average"], let hr = Double(avg) {
                    currentWorkout?.averageHeartRate = hr
                }
            }
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Workout", let builder = currentWorkout, let date = builder.date {
            let workout = GymWorkout(
                id: UUID(),
                date: date,
                name: mapActivityType(builder.activityType ?? ""),
                duration: builder.duration ?? 60,
                calories: builder.calories ?? 300,
                exercises: [], // Would need separate parsing for exercise details
                averageHeartRate: builder.averageHeartRate,
                notes: nil
            )
            workouts.append(workout)
            currentWorkout = nil
        }
    }

    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withSpaceBetweenDateAndTime, .withColonSeparatorInTime, .withTimeZone]
        return formatter.date(from: dateString.replacingOccurrences(of: " ", with: "T"))
    }

    private func mapActivityType(_ type: String) -> String {
        if type.contains("TraditionalStrength") { return "Strength Training" }
        if type.contains("FunctionalStrength") { return "Functional Training" }
        return "Gym Workout"
    }
}

private class WorkoutBuilder {
    var activityType: String?
    var date: Date?
    var duration: Double?
    var calories: Double?
    var averageHeartRate: Double?
}

// MARK: - Data Models
struct ParsedHealthData {
    let workouts: [GymWorkout]
    let bodyMetrics: BodyMetrics
}

struct GymWorkout: Identifiable, Codable {
    let id: UUID
    let date: Date
    let name: String
    let duration: Double // minutes
    let calories: Double
    let exercises: [Exercise]
    let averageHeartRate: Double?
    let notes: String?

    var formattedDuration: String {
        let hours = Int(duration) / 60
        let minutes = Int(duration) % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes) min"
    }

    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

struct Exercise: Identifiable, Codable {
    let id: UUID
    let name: String
    let sets: [ExerciseSet]

    init(id: UUID = UUID(), name: String, sets: [ExerciseSet]) {
        self.id = id
        self.name = name
        self.sets = sets
    }

    var totalVolume: Double {
        sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }

    var maxWeight: Double {
        sets.map(\.weight).max() ?? 0
    }
}

struct ExerciseSet: Identifiable, Codable {
    let id: UUID
    let setNumber: Int
    let weight: Double
    let reps: Int
    let isWarmup: Bool

    init(id: UUID = UUID(), setNumber: Int, weight: Double, reps: Int, isWarmup: Bool = false) {
        self.id = id
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.isWarmup = isWarmup
    }
}

struct BodyMetrics: Codable {
    let weight: Double
    let height: Double
}
