import Foundation

struct Day: Codable {
    let index: Int, date: Date, events: [Event]
}
