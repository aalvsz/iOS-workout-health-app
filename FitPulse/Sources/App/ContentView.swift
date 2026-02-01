import SwiftUI

struct ContentView: View {
    @EnvironmentObject var profile: UserProfile
    @StateObject private var llmService = LLMService.shared
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if !profile.hasCompletedOnboarding {
                OnboardingView(onComplete: {
                    // Reload profile from persistence to get all onboarding data
                    let savedProfile = PersistenceController.shared.loadProfile()
                    profile.name = savedProfile.name
                    profile.weightKg = savedProfile.weightKg
                    profile.heightCm = savedProfile.heightCm
                    profile.age = savedProfile.age
                    profile.sex = savedProfile.sex
                    profile.activityLevel = savedProfile.activityLevel
                    profile.fitnessGoal = savedProfile.fitnessGoal
                    profile.deficitPercentage = savedProfile.deficitPercentage
                    profile.proteinPerKg = savedProfile.proteinPerKg
                    profile.hasCompletedOnboarding = true
                    profile.save()
                })
            } else {
                MainTabView(selectedTab: $selectedTab)
            }
        }
    }
}

struct MainTabView: View {
    @Binding var selectedTab: Int

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Today", systemImage: "house.fill")
                }
                .tag(0)

            GymView()
                .tabItem {
                    Label("Training", systemImage: "dumbbell.fill")
                }
                .tag(1)

            NutritionView()
                .tabItem {
                    Label("Nutrition", systemImage: "fork.knife")
                }
                .tag(2)

            ChatView()
                .tabItem {
                    Label("Coach", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(3)

            EngagementView()
                .tabItem {
                    Label("Progress", systemImage: "trophy.fill")
                }
                .tag(4)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(5)
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView()
        .environmentObject(UserProfile())
        .environmentObject(HealthKitService.shared)
}
