import SwiftUI
import UserNotifications

@main
struct FitPulseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var profile = UserProfile.load()
    @StateObject private var healthService = HealthKitService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(profile)
                .environmentObject(healthService)
                .preferredColorScheme(profile.prefersDarkMode ? .dark : nil)
                .onAppear {
                    setupServices()
                }
        }
    }

    private func setupServices() {
        // Initialize engagement services
        StreakService.shared.initializeStreaksIfNeeded()
        AchievementService.shared.initializeAchievementsIfNeeded()

        // Setup notifications
        Task {
            await NotificationService.shared.setupDefaultNotifications()
        }

        // Auto-load Llama 1B model
        Task {
            await LocalLLMService.shared.autoLoadLlama1BModel()
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = NotificationService.shared

        // Register notification categories
        NotificationService.shared.registerNotificationCategories()

        return true
    }
}
