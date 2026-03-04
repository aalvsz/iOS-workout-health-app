import Foundation
import AuthenticationServices
import CloudKit
import GoogleSignIn

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: AuthUser?
    @Published var isSignedIn: Bool = false

    private let keychainKey = "com.fitpulse.authUser"

    private init() {
        loadFromKeychain()
    }

    // MARK: - Sign in with Apple

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }

            let user = AuthUser(
                id: credential.user,
                provider: .apple,
                email: credential.email,
                displayName: [credential.fullName?.givenName, credential.fullName?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                    .nilIfEmpty,
                cloudKitRecordID: nil,
                createdAt: Date(),
                lastSignInAt: Date()
            )

            setCurrentUser(user)
            Task { await postAuthSetup() }

        case .failure(let error):
            print("Apple Sign-In failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Google Sign-In

    func signInWithGoogle(presenting viewController: UIViewController) async {
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
            let googleUser = result.user
            let user = AuthUser(
                id: googleUser.userID ?? UUID().uuidString,
                provider: .google,
                email: googleUser.profile?.email,
                displayName: googleUser.profile?.name,
                cloudKitRecordID: nil,
                createdAt: Date(),
                lastSignInAt: Date()
            )
            setCurrentUser(user)
            await postAuthSetup()
        } catch {
            print("Google Sign-In failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Post-Auth Setup

    private func postAuthSetup() async {
        await linkToCloudKit()
        await CloudSyncService.shared.performInitialSync()
    }

    // MARK: - CloudKit Link

    func linkToCloudKit() async {
        guard var user = currentUser else { return }

        do {
            let recordID = try await CKContainer.default().userRecordID()
            user.cloudKitRecordID = recordID.recordName
            setCurrentUser(user)
        } catch {
            print("CloudKit link failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Credential Validation

    func checkAppleCredentialState() async {
        guard let user = currentUser, user.provider == .apple else { return }

        do {
            let state = try await ASAuthorizationAppleIDProvider().credentialState(forUserID: user.id)
            if state == .revoked || state == .notFound {
                signOut()
            }
        } catch {
            print("Credential state check failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Sign Out

    func signOut() {
        currentUser = nil
        isSignedIn = false
        deleteFromKeychain()
        CloudSyncService.shared.reset()
    }

    // MARK: - Keychain Storage

    private func setCurrentUser(_ user: AuthUser) {
        currentUser = user
        isSignedIn = true
        saveToKeychain(user)
    }

    private func saveToKeychain(_ user: AuthUser) {
        guard let data = try? JSONEncoder().encode(user) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let user = try? JSONDecoder().decode(AuthUser.self, from: data) else {
            return
        }

        currentUser = user
        isSignedIn = true
    }

    private func deleteFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - String Extension

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
