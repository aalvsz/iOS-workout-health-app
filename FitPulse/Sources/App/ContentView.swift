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
    @State private var showingCoach = false

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(String(localized: "Today"), systemImage: "house.fill")
                }
                .tag(0)

            GymView()
                .tabItem {
                    Label(String(localized: "Training"), systemImage: "dumbbell.fill")
                }
                .tag(1)

            NutritionView()
                .tabItem {
                    Label(String(localized: "Nutrition"), systemImage: "fork.knife")
                }
                .tag(2)

            AnalyticsDashboardView()
                .tabItem {
                    Label(String(localized: "Analytics"), systemImage: "chart.bar.xaxis.ascending")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Label(String(localized: "Profile"), systemImage: "person.fill")
                }
                .tag(4)
        }
        .tint(.blue)
        .overlay(alignment: .bottomTrailing) {
            Button(action: { showingCoach = true }) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 80)
        }
        .sheet(isPresented: $showingCoach) {
            ChatView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UserProfile())
        .environmentObject(HealthKitService.shared)
        .environmentObject(SubscriptionManager.shared)
}
