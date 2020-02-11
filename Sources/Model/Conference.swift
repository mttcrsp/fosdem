import Foundation

struct Conference: Decodable {
    let title: String
    let subtitle: String?
    let venue: String
    let city: String
    let start: Date
    let end: Date
}
