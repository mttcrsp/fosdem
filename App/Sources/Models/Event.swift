import Foundation

struct Event: Codable {
  let id: Int
  let url: URL?
  let room: String
  let track: String

  let title: String
  let summary: String?
  let subtitle: String?
  let abstract: String?

  let date: Date
  let start: DateComponents
  let duration: DateComponents

  let links: [Link]
  let people: [Person]
  let attachments: [Attachment]
}

extension Event {
  var video: Link? {
    links.first { link in link.isMP4Video }
  }

  func isLive(at timestamp: Date) -> Bool {
    hasStarted(by: timestamp) && !hasEnded(by: timestamp)
  }
  
  func hasStarted(by timestamp: Date) -> Bool {
    let lowerbound = date
    return timestamp >= lowerbound
  }

  func hasEnded(by timestamp: Date) -> Bool {
    let upperbound = Calendar.gregorian.date(byAdding: duration, to: date) ?? .distantPast
    return timestamp >= upperbound
  }
}

extension Event: Hashable, Equatable {
  static func == (lhs: Event, rhs: Event) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
