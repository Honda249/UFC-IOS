import Foundation

struct Token: Sendable, Codable, Equatable {
    let value: String
    let expiresAt: Date

    /// 30-second buffer before expiry to avoid races at request send time.
    var isExpired: Bool {
        Date() >= expiresAt.addingTimeInterval(-30)
    }
}
