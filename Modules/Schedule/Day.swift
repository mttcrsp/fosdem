import Foundation

public struct Day: Codable {
  public let index: Int, date: Date, events: [Event]
}
