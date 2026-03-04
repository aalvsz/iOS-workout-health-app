import SwiftUI
import UserNotifications
import CloudKit
import GoogleSignIn

@main
struct FitPulseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var profile = UserProfile.load()
    @StateObject private var healthService = HealthKitService.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var authService = AuthService.shared
    @StateObject private var syncService = CloudSyncService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(profile)
                .environmentObject(healthService)
                .environmentObject(subscriptionManager)
                .environmentObject(authService)
                .environmentObject(syncService)
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

        // Auto-load Gemma 3 1B model
        Task {
            await LocalLLMService.shared.autoLoadModel()
        }

        // Check subscription entitlement
        Task {
            await subscriptionManager.checkEntitlement()
        }

        // Auth + Cloud Sync
        Task {
            if authService.isSignedIn {
                await authService.checkAppleCredentialState()
                await syncService.pullRemoteChanges()
            }
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

    func application(
        _ application: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // Handle Google Sign-In URL callback
        return GIDSignIn.sharedInstance.handle(url)
    }
}
