import Foundation

struct Track {
    let name: String
    let day: Int
    let date: Date
}

extension Track: Equatable {
    static func == (lhs: Track, rhs: Track) -> Bool {
        lhs.name == rhs.name
    }
}
