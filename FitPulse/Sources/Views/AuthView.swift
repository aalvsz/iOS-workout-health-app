import SwiftUI
import AuthenticationServices

// MARK: - Auth Section (Top-level switcher)

struct AuthSectionView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        Section(String(localized: "Account")) {
            if authService.isSignedIn {
                SignedInSectionView()
            } else {
                SignInSectionView()
            }
        }
    }
}

// MARK: - Sign In Section

struct SignInSectionView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        VStack(spacing: 12) {
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                authService.handleAppleSignIn(result: result)
            }
            .signInWithAppleButtonStyle(.whiteOutline)
            .frame(height: 44)

            GoogleSignInButton {
                Task {
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let viewController = windowScene.windows.first?.rootViewController else { return }
                    await authService.signInWithGoogle(presenting: viewController)
                }
            }
            .frame(height: 44)

            Text(String(localized: "Your data stays on device. Sign in to enable cloud backup."))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Signed In Section

struct SignedInSectionView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var syncService: CloudSyncService
    @State private var showingSignOutAlert = false

    var body: some View {
        // User info
        HStack(spacing: 12) {
            Image(systemName: authService.currentUser?.provider == .apple ? "apple.logo" : "g.circle.fill")
                .font(.title2)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(authService.currentUser?.displayName ?? String(localized: "Signed In"))
                    .font(.headline)

                if let email = authService.currentUser?.email {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)

        // Sync status
        SyncStatusView()

        // Sync now button
        Button {
            Task {
                await syncService.performFullSync()
            }
        } label: {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                Text(String(localized: "Sync Now"))
            }
        }
        .disabled(syncService.syncStatus == .syncing)

        // Sign out
        Button(role: .destructive) {
            showingSignOutAlert = true
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text(String(localized: "Sign Out"))
            }
        }
        .alert(String(localized: "Sign Out?"), isPresented: $showingSignOutAlert) {
            Button(String(localized: "Cancel"), role: .cancel) {}
            Button(String(localized: "Sign Out"), role: .destructive) {
                authService.signOut()
            }
        } message: {
            Text(String(localized: "Your data will remain on this device, but cloud sync will stop."))
        }
    }
}

// MARK: - Sync Status View

struct SyncStatusView: View {
    @EnvironmentObject var syncService: CloudSyncService

    var body: some View {
        HStack {
            Text(String(localized: "Sync Status"))

            Spacer()

            switch syncService.syncStatus {
            case .idle:
                Text(String(localized: "Idle"))
                    .foregroundStyle(.secondary)
            case .syncing:
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(String(localized: "Syncing..."))
                        .foregroundStyle(.secondary)
                }
            case .success(let date):
                Text(date, style: .relative)
                    .foregroundStyle(.secondary)
                    + Text(String(localized: " ago"))
                    .foregroundStyle(.secondary)
            case .error(let message):
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Google Sign-In Button

struct GoogleSignInButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "g.circle.fill")
                    .font(.title3)
                Text(String(localized: "Sign in with Google"))
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
