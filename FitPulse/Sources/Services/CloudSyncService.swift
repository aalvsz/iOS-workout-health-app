import Foundation
import CloudKit

@MainActor
class CloudSyncService: ObservableObject {
    static let shared = CloudSyncService()

    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?

    private lazy var container: CKContainer = CKContainer(identifier: "iCloud.com.fitpulse.app")
    private lazy var privateDB: CKDatabase = container.privateCloudDatabase
    private lazy var zoneID = CKRecordZone.ID(zoneName: "FitPulseZone", ownerName: CKCurrentUserDefaultName)
    private let batchSize = 200

    // All record types managed by sync
    static let recordTypes = [
        "UserProfile", "Meal", "WeightEntry", "DailyHealthSummary",
        "DayMealPlan", "HydrationEntry", "Streak", "Achievement",
        "ActiveChallenge", "CompletedChallenge", "GoalPrediction",
        "WorkoutTemplate", "NotificationSettings"
    ]

    private init() {
        lastSyncDate = UserDefaults.standard.object(forKey: "cloudSync_lastSyncDate") as? Date
    }

    // MARK: - Zone Setup

    private func ensureZoneExists() async throws {
        let zone = CKRecordZone(zoneID: zoneID)
        _ = try await privateDB.save(zone)
    }

    // MARK: - Push Single Record

    func pushRecord(type: String, id: String?) async throws {
        guard AuthService.shared.isSignedIn else { return }
        guard let id = id else { return }

        syncStatus = .syncing

        do {
            try await ensureZoneExists()

            let data = loadLocalData(recordType: type, recordID: id)
            guard let data = data else {
                syncStatus = .idle
                return
            }

            let recordID = CKRecord.ID(recordName: "\(type)_\(id)", zoneID: zoneID)
            let record = CKRecord(recordType: type, recordID: recordID)
            record["data"] = data as CKRecordValue
            record["modifiedAt"] = Date() as CKRecordValue
            record["recordIdentifier"] = id as CKRecordValue

            _ = try await privateDB.save(record)
            updateLastSyncDate()
            syncStatus = .success(Date())
        } catch {
            syncStatus = .error(error.localizedDescription)
            throw error
        }
    }

    // MARK: - Pull Remote Changes

    func pullRemoteChanges() async {
        guard AuthService.shared.isSignedIn else { return }

        syncStatus = .syncing

        do {
            try await ensureZoneExists()

            let changeToken = loadChangeToken()
            let configuration = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
            configuration.previousServerChangeToken = changeToken

            let changes = try await fetchChanges(configuration: configuration)

            for record in changes.modifiedRecords {
                applyRemoteRecord(record)
            }

            for recordID in changes.deletedRecordIDs {
                handleRemoteDeletion(recordID)
            }

            if let newToken = changes.newChangeToken {
                saveChangeToken(newToken)
            }

            updateLastSyncDate()
            syncStatus = .success(Date())
        } catch {
            syncStatus = .error(error.localizedDescription)
        }
    }

    // MARK: - Initial Sync (after first login)

    func performInitialSync() async {
        guard AuthService.shared.isSignedIn else { return }

        syncStatus = .syncing

        do {
            try await ensureZoneExists()
            await setupSubscription()

            // Push all local data
            try await pushAllLocalData()

            // Pull remote data
            await pullRemoteChanges()

            updateLastSyncDate()
            syncStatus = .success(Date())
        } catch {
            syncStatus = .error(error.localizedDescription)
        }
    }

    // MARK: - Full Sync

    func performFullSync() async {
        guard AuthService.shared.isSignedIn else { return }

        syncStatus = .syncing

        do {
            await pullRemoteChanges()
            try await pushAllLocalData()

            updateLastSyncDate()
            syncStatus = .success(Date())
        } catch {
            syncStatus = .error(error.localizedDescription)
        }
    }

    // MARK: - Remote Notification Handler

    func handleRemoteNotification() {
        Task {
            await pullRemoteChanges()
        }
    }

    // MARK: - Reset

    func reset() {
        syncStatus = .idle
        lastSyncDate = nil
        UserDefaults.standard.removeObject(forKey: "cloudSync_lastSyncDate")
        clearChangeToken()
    }

    // MARK: - CKRecord Mapping

    private func toCKRecord<T: Codable>(_ item: T, recordType: String, recordID: String) -> CKRecord? {
        guard let data = try? JSONEncoder().encode(item) else { return nil }

        let ckRecordID = CKRecord.ID(recordName: "\(recordType)_\(recordID)", zoneID: zoneID)
        let record = CKRecord(recordType: recordType, recordID: ckRecordID)
        record["data"] = data as CKRecordValue
        record["modifiedAt"] = Date() as CKRecordValue
        record["recordIdentifier"] = recordID as CKRecordValue
        return record
    }

    private func fromCKRecord<T: Codable>(_ record: CKRecord) -> T? {
        guard let data = record["data"] as? Data else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Conflict Resolution

    private func resolveConflict(local: CKRecord, remote: CKRecord) -> CKRecord {
        let localDate = local["modifiedAt"] as? Date ?? .distantPast
        let remoteDate = remote["modifiedAt"] as? Date ?? .distantPast
        return localDate >= remoteDate ? local : remote
    }

    // MARK: - Push All Local Data

    private func pushAllLocalData() async throws {
        let persistence = PersistenceController.shared
        var records: [CKRecord] = []

        // UserProfile
        let profile = UserProfile.load()
        if let record = toCKRecord(profile, recordType: "UserProfile", recordID: profile.id.uuidString) {
            records.append(record)
        }

        // Meals
        for meal in persistence.loadMeals() {
            if let record = toCKRecord(meal, recordType: "Meal", recordID: meal.id.uuidString) {
                records.append(record)
            }
        }

        // Weight entries
        for entry in persistence.loadWeightHistory() {
            if let record = toCKRecord(entry, recordType: "WeightEntry", recordID: entry.id.uuidString) {
                records.append(record)
            }
        }

        // Daily summaries
        for summary in persistence.loadCachedSummaries() {
            if let record = toCKRecord(summary, recordType: "DailyHealthSummary", recordID: summary.id.uuidString) {
                records.append(record)
            }
        }

        // Meal plans
        for plan in persistence.loadSavedMealPlans() {
            if let record = toCKRecord(plan, recordType: "DayMealPlan", recordID: plan.date.ISO8601Format()) {
                records.append(record)
            }
        }

        // Hydration entries
        for entry in persistence.loadHydrationEntries(for: Date()) {
            if let record = toCKRecord(entry, recordType: "HydrationEntry", recordID: entry.id.uuidString) {
                records.append(record)
            }
        }

        // Streaks
        for streak in persistence.loadStreaks() {
            if let record = toCKRecord(streak, recordType: "Streak", recordID: streak.type.rawValue) {
                records.append(record)
            }
        }

        // Achievements
        for achievement in persistence.loadAchievements() {
            if let record = toCKRecord(achievement, recordType: "Achievement", recordID: achievement.id) {
                records.append(record)
            }
        }

        // Active challenges
        for challenge in persistence.loadActiveChallenges() {
            if let record = toCKRecord(challenge, recordType: "ActiveChallenge", recordID: challenge.id.uuidString) {
                records.append(record)
            }
        }

        // Completed challenges
        for challenge in persistence.loadCompletedChallenges() {
            if let record = toCKRecord(challenge, recordType: "CompletedChallenge", recordID: challenge.id.uuidString) {
                records.append(record)
            }
        }

        // Goal predictions
        for prediction in persistence.loadGoalPredictions() {
            if let record = toCKRecord(prediction, recordType: "GoalPrediction", recordID: prediction.goalType.rawValue) {
                records.append(record)
            }
        }

        // Workout templates
        for template in persistence.loadWorkoutTemplates() {
            if let record = toCKRecord(template, recordType: "WorkoutTemplate", recordID: template.id.uuidString) {
                records.append(record)
            }
        }

        // Push in batches
        try await pushRecordBatches(records)
    }

    private func pushRecordBatches(_ records: [CKRecord]) async throws {
        let batches = stride(from: 0, to: records.count, by: batchSize).map {
            Array(records[$0..<min($0 + batchSize, records.count)])
        }

        for batch in batches {
            let operation = CKModifyRecordsOperation(recordsToSave: batch)
            operation.savePolicy = .changedKeys
            operation.qualityOfService = .userInitiated

            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                operation.modifyRecordsResultBlock = { result in
                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                self.privateDB.add(operation)
            }
        }
    }

    // MARK: - Fetch Changes

    private struct ChangeResult {
        var modifiedRecords: [CKRecord] = []
        var deletedRecordIDs: [CKRecord.ID] = []
        var newChangeToken: CKServerChangeToken?
    }

    private func fetchChanges(configuration: CKFetchRecordZoneChangesOperation.ZoneConfiguration) async throws -> ChangeResult {
        let operation = CKFetchRecordZoneChangesOperation(
            recordZoneIDs: [zoneID],
            configurationsByRecordZoneID: [zoneID: configuration]
        )

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ChangeResult, Error>) in
            var result = ChangeResult()

            operation.recordWasChangedBlock = { _, recordResult in
                if case .success(let record) = recordResult {
                    result.modifiedRecords.append(record)
                }
            }

            operation.recordWithIDWasDeletedBlock = { recordID, _ in
                result.deletedRecordIDs.append(recordID)
            }

            operation.recordZoneFetchResultBlock = { (_: CKRecordZone.ID, fetchResult: Result<(serverChangeToken: CKServerChangeToken, clientChangeTokenData: Data?, moreComing: Bool), Error>) in
                switch fetchResult {
                case .success(let value):
                    result.newChangeToken = value.serverChangeToken
                case .failure:
                    break
                }
            }

            operation.fetchRecordZoneChangesResultBlock = { overallResult in
                switch overallResult {
                case .success:
                    continuation.resume(returning: result)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            operation.qualityOfService = .userInitiated
            self.privateDB.add(operation)
        }
    }

    // MARK: - Apply Remote Record to Local

    private func applyRemoteRecord(_ record: CKRecord) {
        let persistence = PersistenceController.shared
        let recordType = record.recordType
        let remoteModifiedAt = record["modifiedAt"] as? Date ?? .distantPast
        let recordIdentifier = record["recordIdentifier"] as? String ?? ""

        // Check local modifiedAt — last-write-wins
        let localModifiedAt = persistence.getModifiedAt(for: recordType, id: recordIdentifier)
        if let localDate = localModifiedAt, localDate >= remoteModifiedAt {
            return // Local is newer, skip
        }

        guard let data = record["data"] as? Data else { return }

        switch recordType {
        case "UserProfile":
            if let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
                persistence.saveProfile(profile)
            }
        case "Meal":
            if let meal = try? JSONDecoder().decode(Meal.self, from: data) {
                persistence.saveMeal(meal)
            }
        case "WeightEntry":
            if let entry = try? JSONDecoder().decode(WeightEntry.self, from: data) {
                persistence.saveWeightEntry(entry)
            }
        case "Streak":
            if let streak = try? JSONDecoder().decode(Streak.self, from: data) {
                persistence.updateStreak(streak)
            }
        case "Achievement":
            if let achievement = try? JSONDecoder().decode(Achievement.self, from: data) {
                persistence.updateAchievement(achievement)
            }
        case "ActiveChallenge", "CompletedChallenge":
            if let challenge = try? JSONDecoder().decode(Challenge.self, from: data) {
                persistence.saveChallenge(challenge)
            }
        case "GoalPrediction":
            if let prediction = try? JSONDecoder().decode(GoalPrediction.self, from: data) {
                persistence.saveGoalPrediction(prediction)
            }
        case "HydrationEntry":
            if let entry = try? JSONDecoder().decode(HydrationEntry.self, from: data) {
                persistence.saveHydrationEntry(entry)
            }
        case "WorkoutTemplate":
            if let template = try? JSONDecoder().decode(WorkoutTemplate.self, from: data) {
                persistence.saveWorkoutTemplate(template)
            }
        case "DayMealPlan":
            if let plan = try? JSONDecoder().decode(DayMealPlan.self, from: data) {
                persistence.saveMealPlan(plan)
            }
        default:
            break
        }

        // Update local modifiedAt to match remote
        persistence.setModifiedAt(remoteModifiedAt, for: recordType, id: recordIdentifier)
    }

    private func handleRemoteDeletion(_ recordID: CKRecord.ID) {
        // For now, deletions are not synced to avoid accidental data loss
        // A future version could implement soft-delete with a "deleted" flag
    }

    // MARK: - Load Local Data for Push

    private func loadLocalData(recordType: String, recordID: String) -> Data? {
        let persistence = PersistenceController.shared

        switch recordType {
        case "UserProfile":
            let profile = UserProfile.load()
            return try? JSONEncoder().encode(profile)
        case "Meal":
            guard let uuid = UUID(uuidString: recordID) else { return nil }
            let meal = persistence.loadMeals().first { $0.id == uuid }
            return try? JSONEncoder().encode(meal)
        case "WeightEntry":
            guard let uuid = UUID(uuidString: recordID) else { return nil }
            let entry = persistence.loadWeightHistory().first { $0.id == uuid }
            return try? JSONEncoder().encode(entry)
        case "Streak":
            let streaks = persistence.loadStreaks()
            guard let type = StreakType(rawValue: recordID) else { return nil }
            let streak = streaks.first { $0.type == type }
            return try? JSONEncoder().encode(streak)
        case "Achievement":
            let achievement = persistence.getAchievement(recordID)
            return try? JSONEncoder().encode(achievement)
        case "ActiveChallenge":
            guard let uuid = UUID(uuidString: recordID) else { return nil }
            let challenge = persistence.loadActiveChallenges().first { $0.id == uuid }
            return try? JSONEncoder().encode(challenge)
        case "CompletedChallenge":
            guard let uuid = UUID(uuidString: recordID) else { return nil }
            let challenge = persistence.loadCompletedChallenges().first { $0.id == uuid }
            return try? JSONEncoder().encode(challenge)
        case "GoalPrediction":
            guard let goalType = GoalType(rawValue: recordID) else { return nil }
            let prediction = persistence.getGoalPrediction(for: goalType)
            return try? JSONEncoder().encode(prediction)
        case "HydrationEntry":
            // Hydration entries loaded by date; for push we encode the specific entry
            return nil
        case "WorkoutTemplate":
            guard let uuid = UUID(uuidString: recordID) else { return nil }
            let template = persistence.loadWorkoutTemplates().first { $0.id == uuid }
            return try? JSONEncoder().encode(template)
        case "DayMealPlan":
            let plans = persistence.loadSavedMealPlans()
            let plan = plans.first { $0.date.ISO8601Format() == recordID }
            return try? JSONEncoder().encode(plan)
        default:
            return nil
        }
    }

    // MARK: - Subscription

    private func setupSubscription() async {
        let subscription = CKDatabaseSubscription(subscriptionID: "fitpulse-private-changes")
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo

        do {
            _ = try await privateDB.save(subscription)
        } catch {
            // Subscription might already exist — not critical
            print("Subscription setup: \(error.localizedDescription)")
        }
    }

    // MARK: - Change Token Persistence

    private func saveChangeToken(_ token: CKServerChangeToken) {
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) {
            UserDefaults.standard.set(data, forKey: "ck_changeToken_\(zoneID.zoneName)")
        }
    }

    private func loadChangeToken() -> CKServerChangeToken? {
        guard let data = UserDefaults.standard.data(forKey: "ck_changeToken_\(zoneID.zoneName)") else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data)
    }

    private func clearChangeToken() {
        UserDefaults.standard.removeObject(forKey: "ck_changeToken_\(zoneID.zoneName)")
    }

    // MARK: - Last Sync Date

    private func updateLastSyncDate() {
        let date = Date()
        lastSyncDate = date
        UserDefaults.standard.set(date, forKey: "cloudSync_lastSyncDate")
    }
}
