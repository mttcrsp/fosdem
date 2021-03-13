import Foundation

public struct Track: Codable {
  public let name: String, day: Int, date: Date

  public init(name: String, day: Int, date: Date) {
    self.name = name
    self.day = day
    self.date = date
  }
}

extension Track: Equatable {
  public static func == (lhs: Track, rhs: Track) -> Bool {
    lhs.name == rhs.name
  }
}
