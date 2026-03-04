import Foundation
import HealthKit
import Combine
import UIKit

@MainActor
class HealthKitService: ObservableObject {
    static let shared = HealthKitService()

    private let healthStore = HKHealthStore()
    @Published var isAuthorized = false
    @Published var authorizationError: String?

    // Auto-sync properties
    @Published var todaySummary: DailyHealthSummary?
    @Published var lastSyncDate: Date?
    @Published var isSyncing = false

    private var observerQueries: [HKObserverQuery] = []
    private var backgroundObserver: NSObjectProtocol?
    private var foregroundObserver: NSObjectProtocol?

    // Types to read
    private let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()

        // Quantity types
        let quantityTypes: [HKQuantityTypeIdentifier] = [
            .activeEnergyBurned,
            .basalEnergyBurned,
            .stepCount,
            .distanceWalkingRunning,
            .distanceCycling,
            .heartRate,
            .restingHeartRate,
            .heartRateVariabilitySDNN,
            .bodyMass,
            .height,
            .bodyFatPercentage
        ]

        for identifier in quantityTypes {
            if let type = HKQuantityType.quantityType(forIdentifier: identifier) {
                types.insert(type)
            }
        }

        // Category types
        if let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepType)
        }

        // Workout type
        types.insert(HKWorkoutType.workoutType())

        return types
    }()

    // Types to write
    private let writeTypes: Set<HKSampleType> = {
        var types = Set<HKSampleType>()

        if let bodyMass = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            types.insert(bodyMass)
        }

        types.insert(HKWorkoutType.workoutType())

        return types
    }()

    private init() {
        setupAppLifecycleObservers()
    }

    /// Clean up observers - call this when no longer needed
    func cleanup() {
        stopObservingHealthData()
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
            foregroundObserver = nil
        }
        if let observer = backgroundObserver {
            NotificationCenter.default.removeObserver(observer)
            backgroundObserver = nil
        }
    }

    // MARK: - App Lifecycle Observers

    private func setupAppLifecycleObservers() {
        // Sync when app comes to foreground
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.syncHealthData()
            }
        }

        // Also sync when app becomes active (handles initial launch)
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                // Only sync if we haven't synced recently (within last 30 seconds)
                if let lastSync = self.lastSyncDate,
                   Date().timeIntervalSince(lastSync) < 30 {
                    return
                }
                await self.syncHealthData()
            }
        }
    }

    // MARK: - Authorization
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationError = "Health data is not available on this device"
            throw HealthKitError.notAvailable
        }

        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            isAuthorized = true

            // Start observing health data changes after authorization
            startObservingHealthData()

            // Enable background delivery for key types
            enableBackgroundDelivery()

            // Initial sync
            await syncHealthData()
        } catch {
            authorizationError = error.localizedDescription
            throw HealthKitError.authorizationFailed(error)
        }
    }

    // MARK: - Auto-Sync

    /// Syncs today's health data from HealthKit
    func syncHealthData() async {
        guard isAuthorized || HKHealthStore.isHealthDataAvailable() else { return }

        // Avoid concurrent syncs
        guard !isSyncing else { return }
        isSyncing = true

        defer { isSyncing = false }

        do {
            let summary = try await fetchDailySummary(for: Date())
            todaySummary = summary
            lastSyncDate = Date()

            // Cache the data
            PersistenceController.shared.cacheDailySummary(summary)

            // Post notification for any listeners
            NotificationCenter.default.post(name: .healthDataDidUpdate, object: summary)
        } catch {
            print("Health sync error: \(error.localizedDescription)")
        }
    }

    // MARK: - HealthKit Observers

    /// Start observing changes to key health data types
    private func startObservingHealthData() {
        // Types to observe for real-time updates
        let typesToObserve: [HKQuantityTypeIdentifier] = [
            .activeEnergyBurned,
            .stepCount,
            .heartRate,
            .bodyMass
        ]

        for identifier in typesToObserve {
            guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { continue }

            let query = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, completionHandler, error in
                if error != nil {
                    completionHandler()
                    return
                }

                // Trigger sync on main actor
                Task { @MainActor in
                    await self?.syncHealthData()
                }

                completionHandler()
            }

            healthStore.execute(query)
            observerQueries.append(query)
        }

        // Also observe workouts
        let workoutQuery = HKObserverQuery(sampleType: HKWorkoutType.workoutType(), predicate: nil) { [weak self] _, completionHandler, error in
            if error != nil {
                completionHandler()
                return
            }

            Task { @MainActor in
                await self?.syncHealthData()
            }

            completionHandler()
        }

        healthStore.execute(workoutQuery)
        observerQueries.append(workoutQuery)

        // Observe sleep
        if let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            let sleepQuery = HKObserverQuery(sampleType: sleepType, predicate: nil) { [weak self] _, completionHandler, error in
                if error != nil {
                    completionHandler()
                    return
                }

                Task { @MainActor in
                    await self?.syncHealthData()
                }

                completionHandler()
            }

            healthStore.execute(sleepQuery)
            observerQueries.append(sleepQuery)
        }
    }

    /// Stop all observer queries
    private func stopObservingHealthData() {
        for query in observerQueries {
            healthStore.stop(query)
        }
        observerQueries.removeAll()
    }

    /// Enable background delivery for key health types
    private func enableBackgroundDelivery() {
        let typesForBackground: [HKQuantityTypeIdentifier] = [
            .activeEnergyBurned,
            .stepCount,
            .bodyMass
        ]

        for identifier in typesForBackground {
            guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { continue }

            healthStore.enableBackgroundDelivery(for: type, frequency: .immediate) { success, error in
                if let error = error {
                    print("Background delivery error for \(identifier): \(error.localizedDescription)")
                }
            }
        }

        // Enable for workouts
        healthStore.enableBackgroundDelivery(for: HKWorkoutType.workoutType(), frequency: .immediate) { success, error in
            if let error = error {
                print("Background delivery error for workouts: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Fetch Daily Summary
    func fetchDailySummary(for date: Date) async throws -> DailyHealthSummary {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        async let activeCalories = fetchSum(for: .activeEnergyBurned, from: startOfDay, to: endOfDay)
        async let basalCalories = fetchSum(for: .basalEnergyBurned, from: startOfDay, to: endOfDay)
        async let steps = fetchSum(for: .stepCount, from: startOfDay, to: endOfDay)
        async let distance = fetchSum(for: .distanceWalkingRunning, from: startOfDay, to: endOfDay)
        async let sleepHours = fetchSleepHours(from: startOfDay, to: endOfDay)
        async let hrv = fetchAverage(for: .heartRateVariabilitySDNN, from: startOfDay, to: endOfDay)
        async let restingHR = fetchAverage(for: .restingHeartRate, from: startOfDay, to: endOfDay)
        async let workouts = fetchWorkouts(from: startOfDay, to: endOfDay)

        let workoutList = try await workouts
        let workoutMinutes = workoutList.reduce(0) { $0 + $1.durationMinutes }
        let workoutCalories = workoutList.reduce(0) { $0 + $1.activeCalories }

        return DailyHealthSummary(
            date: date,
            activeCalories: try await activeCalories,
            basalCalories: try await basalCalories,
            steps: Int(try await steps),
            distanceKm: try await distance / 1000,
            sleepHours: try await sleepHours,
            hrvMs: try await hrv,
            restingHeartRate: try await restingHR,
            workoutCount: workoutList.count,
            workoutMinutes: workoutMinutes,
            workoutCalories: workoutCalories
        )
    }

    // MARK: - Fetch Historical Data
    func fetchDailySummaries(days: Int) async throws -> [DailyHealthSummary] {
        var summaries: [DailyHealthSummary] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for dayOffset in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                do {
                    let summary = try await fetchDailySummary(for: date)
                    summaries.append(summary)
                } catch {
                    // Continue with other days even if one fails
                    continue
                }
            }
        }

        return summaries.sorted { $0.date < $1.date }
    }

    // MARK: - Fetch Workouts
    func fetchWorkouts(from startDate: Date, to endDate: Date) async throws -> [Workout] {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKWorkoutType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let workouts = (samples as? [HKWorkout])?.map { hkWorkout in
                    Workout(
                        id: hkWorkout.uuid,
                        date: hkWorkout.startDate,
                        activityType: hkWorkout.workoutActivityType.displayName,
                        activityIcon: hkWorkout.workoutActivityType.icon,
                        durationMinutes: hkWorkout.duration / 60,
                        activeCalories: hkWorkout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                        distance: hkWorkout.totalDistance?.doubleValue(for: .meter()),
                        averageHeartRate: nil,
                        startTime: hkWorkout.startDate,
                        endTime: hkWorkout.endDate
                    )
                } ?? []

                continuation.resume(returning: workouts)
            }

            healthStore.execute(query)
        }
    }

    func fetchRecentWorkouts(limit: Int = 50) async throws -> [Workout] {
        let endDate = Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -90, to: endDate) else { return [] }
        let allWorkouts = try await fetchWorkouts(from: startDate, to: endDate)
        return Array(allWorkouts.prefix(limit))
    }

    /// Force-refresh all health data. Called from ProfileView's "Sync with Apple Health" button.
    func syncAllHealthData() async {
        guard !isSyncing else { return }
        isSyncing = true

        do {
            let summary = try await fetchDailySummary(for: Date())
            todaySummary = summary
            lastSyncDate = Date()

            PersistenceController.shared.cacheDailySummary(summary)
            NotificationCenter.default.post(name: .healthDataDidUpdate, object: summary)
        } catch {
            print("Full health sync error: \(error.localizedDescription)")
            lastSyncDate = Date()
        }

        isSyncing = false
    }

    // MARK: - Weight
    func fetchLatestWeight() async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return nil
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let weight = (samples?.first as? HKQuantitySample)?
                    .quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: weight)
            }

            healthStore.execute(query)
        }
    }

    func saveWeight(_ weightKg: Double, date: Date = Date()) async throws {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitError.typeNotAvailable
        }

        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weightKg)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)

        try await healthStore.save(sample)
    }

    func fetchWeightHistory(days: Int = 90) async throws -> [WeightEntry] {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return []
        }

        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let entries = (samples as? [HKQuantitySample])?.map { sample in
                    WeightEntry(
                        id: sample.uuid,
                        date: sample.startDate,
                        weightKg: sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                    )
                } ?? []

                continuation.resume(returning: entries)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Private Helpers
    private func fetchSum(for identifier: HKQuantityTypeIdentifier, from startDate: Date, to endDate: Date) async throws -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            return 0
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let unit = self.unit(for: identifier)
                let sum = statistics?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: sum)
            }

            healthStore.execute(query)
        }
    }

    private func fetchAverage(for identifier: HKQuantityTypeIdentifier, from startDate: Date, to endDate: Date) async throws -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            return 0
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let unit = self.unit(for: identifier)
                let avg = statistics?.averageQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: avg)
            }

            healthStore.execute(query)
        }
    }

    private func fetchSleepHours(from startDate: Date, to endDate: Date) async throws -> Double {
        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return 0
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                var totalSeconds: Double = 0

                for sample in samples as? [HKCategorySample] ?? [] {
                    // Only count asleep states
                    if sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue {
                        totalSeconds += sample.endDate.timeIntervalSince(sample.startDate)
                    }
                }

                continuation.resume(returning: totalSeconds / 3600)
            }

            healthStore.execute(query)
        }
    }

    private nonisolated func unit(for identifier: HKQuantityTypeIdentifier) -> HKUnit {
        switch identifier {
        case .activeEnergyBurned, .basalEnergyBurned:
            return .kilocalorie()
        case .stepCount:
            return .count()
        case .distanceWalkingRunning, .distanceCycling:
            return .meter()
        case .heartRate, .restingHeartRate:
            return HKUnit.count().unitDivided(by: .minute())
        case .heartRateVariabilitySDNN:
            return .secondUnit(with: .milli)
        case .bodyMass:
            return .gramUnit(with: .kilo)
        case .height:
            return .meterUnit(with: .centi)
        case .bodyFatPercentage:
            return .percent()
        default:
            return .count()
        }
    }
}

// MARK: - Errors
enum HealthKitError: LocalizedError {
    case notAvailable
    case authorizationFailed(Error)
    case typeNotAvailable
    case queryFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .authorizationFailed(let error):
            return "Failed to authorize HealthKit: \(error.localizedDescription)"
        case .typeNotAvailable:
            return "The requested health data type is not available"
        case .queryFailed(let error):
            return "Failed to query health data: \(error.localizedDescription)"
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let healthDataDidUpdate = Notification.Name("healthDataDidUpdate")
}
