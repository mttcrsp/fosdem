import Foundation

struct Track: Codable {
  let name: String, day: Int, date: Date
}

extension Track: Equatable {
  static func == (lhs: Track, rhs: Track) -> Bool {
    lhs.name == rhs.name
  }
}

extension Track {
  var formattedName: String {
    TrackFormatter().formattedName(from: name)
  }
}
