import Foundation

struct Event: Codable {
  let id: Int
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
    links.first { link in link.url?.pathExtension == "mp4" }
  }

  func isLive(at timestamp: Date) -> Bool {
    let calendar = Calendar.autoupdatingCurrent
    let lowerbound = date
    let upperbound = calendar.date(byAdding: duration, to: date) ?? .distantPast
    return lowerbound < timestamp && timestamp < upperbound
  }

  func isSameDay(as date: Date) -> Bool {
    guard let timezone = TimeZone(identifier: "Europe/Brussels") else {
      return false
    }

    let calendar = Calendar.autoupdatingCurrent
    let components1 = calendar.dateComponents(in: timezone, from: self.date)
    let components2 = calendar.dateComponents(in: timezone, from: date)

    return (
      components1.month == components2.month &&
        components1.year == components2.year &&
        components1.day == components2.day
    )
  }

  func isSameWeekday(as event: Event) -> Bool {
    let lhs = Calendar.autoupdatingCurrent.component(.weekday, from: date)
    let rhs = Calendar.autoupdatingCurrent.component(.weekday, from: event.date)
    return lhs == rhs
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
