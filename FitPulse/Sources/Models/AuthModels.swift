import Foundation

enum AuthProvider: String, Codable {
    case apple
    case google
}

struct AuthUser: Codable {
    let id: String
    let provider: AuthProvider
    let email: String?
    let displayName: String?
    var cloudKitRecordID: String?
    let createdAt: Date
    var lastSignInAt: Date
}

enum SyncStatus: Equatable {
    case idle
    case syncing
    case success(Date)
    case error(String)
}
