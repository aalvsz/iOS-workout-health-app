import Foundation
import UserNotifications

class NotificationService: NSObject {
    static let shared = NotificationService()

    private let persistence = PersistenceController.shared
    private let notificationCenter = UNUserNotificationCenter.current()

    private override init() {
        super.init()
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            let granted = try await notificationCenter.requestAuthorization(options: options)
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Schedule Notifications

    func scheduleMorningMotivation(at hour: Int = 7, minute: Int = 30) {
        let content = createNotificationContent(
            title: "Rise and Shine!",
            body: "Start your day strong. What's your fitness goal today?",
            type: .morningMotivation
        )

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        scheduleNotification(content: content, trigger: trigger, identifier: "morning_motivation")
    }

    func scheduleHydrationReminders() {
        let times = [(10, 0), (13, 0), (16, 0), (19, 0)] // 10am, 1pm, 4pm, 7pm

        for (index, (hour, minute)) in times.enumerated() {
            let content = createNotificationContent(
                title: "Hydration Check",
                body: getHydrationMessage(for: index),
                type: .hydrationReminder
            )

            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            scheduleNotification(content: content, trigger: trigger, identifier: "hydration_\(index)")
        }
    }

    func scheduleStreakAtRiskAlert(streakType: StreakType, currentCount: Int) {
        // Schedule for 8 PM
        let content = createNotificationContent(
            title: "Don't Break Your Streak!",
            body: "Your \(currentCount)-day \(streakType.rawValue.lowercased()) streak is at risk. Log your activity now!",
            type: .streakAtRisk
        )

        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        scheduleNotification(content: content, trigger: trigger, identifier: "streak_risk_\(streakType.rawValue)")
    }

    func scheduleWorkoutReminder(at hour: Int = 18, minute: Int = 0) {
        let content = createNotificationContent(
            title: "Workout Time",
            body: "Ready to crush your workout? Let's go!",
            type: .workoutReminder
        )

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        scheduleNotification(content: content, trigger: trigger, identifier: "workout_reminder")
    }

    // MARK: - Immediate Notifications

    func sendAchievementUnlockedNotification(_ achievement: Achievement) {
        let content = createNotificationContent(
            title: "Achievement Unlocked!",
            body: "\(achievement.title) - \(achievement.description)",
            type: .achievementUnlock
        )

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        scheduleNotification(content: content, trigger: trigger, identifier: "achievement_\(achievement.id)")
    }

    func sendChallengeCompleteNotification(_ challenge: Challenge) {
        let content = createNotificationContent(
            title: "Challenge Complete!",
            body: "You crushed the \(challenge.title) challenge!",
            type: .challengeUpdate
        )

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        scheduleNotification(content: content, trigger: trigger, identifier: "challenge_complete_\(challenge.id.uuidString)")
    }

    func sendGoalMilestoneNotification(currentWeight: Double, targetWeight: Double) {
        let progress = abs(currentWeight - targetWeight)
        let content = createNotificationContent(
            title: "Progress Update",
            body: String(format: "You're %.1f kg from your goal. Keep going!", progress),
            type: .goalMilestone
        )

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        scheduleNotification(content: content, trigger: trigger, identifier: "goal_milestone")
    }

    // MARK: - Cancel Notifications

    func cancelNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    func cancelStreakRiskNotifications() {
        let identifiers = StreakType.allCases.map { "streak_risk_\($0.rawValue)" }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func cancelHydrationReminders() {
        let identifiers = (0..<4).map { "hydration_\($0)" }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - Setup Default Schedule

    func setupDefaultNotifications() async {
        let granted = await requestPermission()
        guard granted else { return }

        scheduleMorningMotivation()
        scheduleHydrationReminders()
        scheduleWorkoutReminder()
    }

    // MARK: - Private Helpers

    private func createNotificationContent(
        title: String,
        body: String,
        type: CoachNotificationType
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["type": type.rawValue]

        // Set category for actions
        switch type {
        case .hydrationReminder:
            content.categoryIdentifier = "HYDRATION_CATEGORY"
        case .workoutReminder:
            content.categoryIdentifier = "WORKOUT_CATEGORY"
        case .streakAtRisk:
            content.categoryIdentifier = "STREAK_CATEGORY"
        default:
            break
        }

        return content
    }

    private func scheduleNotification(
        content: UNMutableNotificationContent,
        trigger: UNNotificationTrigger,
        identifier: String
    ) {
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }

        // Save to persistence
        let notification = CoachNotification(
            type: CoachNotificationType(rawValue: content.userInfo["type"] as? String ?? "") ?? .morningMotivation,
            title: content.title,
            body: content.body,
            scheduledDate: Date(),
            actionType: .openApp
        )
        persistence.saveScheduledNotification(notification)
    }

    private func getHydrationMessage(for index: Int) -> String {
        let messages = [
            "Morning hydration check! Start your day with a glass of water.",
            "Midday reminder: Stay hydrated to keep your energy up!",
            "Afternoon boost: A glass of water helps you power through.",
            "Evening reminder: Keep sipping to hit your hydration goal!"
        ]
        return messages[min(index, messages.count - 1)]
    }

    // MARK: - Notification Categories

    func registerNotificationCategories() {
        // Hydration actions
        let logWaterAction = UNNotificationAction(
            identifier: "LOG_WATER",
            title: "Log Water",
            options: .foreground
        )

        let hydrationCategory = UNNotificationCategory(
            identifier: "HYDRATION_CATEGORY",
            actions: [logWaterAction],
            intentIdentifiers: [],
            options: []
        )

        // Workout actions
        let startWorkoutAction = UNNotificationAction(
            identifier: "START_WORKOUT",
            title: "Start Workout",
            options: .foreground
        )

        let workoutCategory = UNNotificationCategory(
            identifier: "WORKOUT_CATEGORY",
            actions: [startWorkoutAction],
            intentIdentifiers: [],
            options: []
        )

        // Streak actions
        let viewProgressAction = UNNotificationAction(
            identifier: "VIEW_PROGRESS",
            title: "View Progress",
            options: .foreground
        )

        let streakCategory = UNNotificationCategory(
            identifier: "STREAK_CATEGORY",
            actions: [viewProgressAction],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([
            hydrationCategory,
            workoutCategory,
            streakCategory
        ])
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier

        // Handle notification tap or action
        switch actionIdentifier {
        case "LOG_WATER":
            NotificationCenter.default.post(name: .notificationActionLogWater, object: nil)
        case "START_WORKOUT":
            NotificationCenter.default.post(name: .notificationActionStartWorkout, object: nil)
        case "VIEW_PROGRESS":
            NotificationCenter.default.post(name: .notificationActionViewProgress, object: nil)
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            if let type = userInfo["type"] as? String {
                NotificationCenter.default.post(
                    name: .notificationTapped,
                    object: nil,
                    userInfo: ["type": type]
                )
            }
        default:
            break
        }

        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let notificationActionLogWater = Notification.Name("notificationActionLogWater")
    static let notificationActionStartWorkout = Notification.Name("notificationActionStartWorkout")
    static let notificationActionViewProgress = Notification.Name("notificationActionViewProgress")
    static let notificationTapped = Notification.Name("notificationTapped")
}
