import Foundation
import SwiftData

@Model
final class Client {
    var id: String
    var name: String
    var email: String
    var company: String
    var address: String
    var notes: String
    var createdAt: Date

    init(
        name: String,
        email: String = "",
        company: String = "",
        address: String = "",
        notes: String = ""
    ) {
        let ts = Int(Date().timeIntervalSince1970 * 1000)
        let uuid = UUID().uuidString.prefix(6)
        self.id = "cli_\(ts)_\(uuid)"
        self.name = name
        self.email = email
        self.company = company
        self.address = address
        self.notes = notes
        self.createdAt = .now
    }
}
