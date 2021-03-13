import Foundation

public struct Conference: Codable {
  public let title: String
  public let subtitle: String?
  public let venue: String
  public let city: String?
  public let start: Date
  public let end: Date
}
