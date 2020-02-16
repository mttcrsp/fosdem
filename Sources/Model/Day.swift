import Foundation

struct Day: Decodable {
    let index: Int, date: Date, events: [Event]
}
