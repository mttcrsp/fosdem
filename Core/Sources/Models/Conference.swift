import Foundation

struct Conference: Codable {
  let title: String
  let subtitle: String?
  let venue: String
  let city: String?
  let start: Date
  let end: Date
}
