import Foundation
import L10n

public struct Event: Codable {
  public let id: Int
  public let room: String
  public let track: String

  public let title: String
  public let summary: String?
  public let subtitle: String?
  public let abstract: String?

  public let date: Date
  public let start: DateComponents
  public let duration: DateComponents

  public let links: [Link]
  public let people: [Person]
  public let attachments: [Attachment]

  public init(id: Int, room: String, track: String, title: String, summary: String?, subtitle: String?, abstract: String?, date: Date, start: DateComponents, duration: DateComponents, links: [Link], people: [Person], attachments: [Attachment]) {
    self.id = id
    self.room = room
    self.track = track
    self.title = title
    self.summary = summary
    self.subtitle = subtitle
    self.abstract = abstract
    self.date = date
    self.start = start
    self.duration = duration
    self.links = links
    self.people = people
    self.attachments = attachments
  }
}

public extension Event {
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

public extension Event {
  var formattedStart: String? {
    DateComponentsFormatter.time.string(from: start)
  }

  var formattedWeekday: String? {
    DateFormatter.weekday.string(from: date)
  }

  var formattedSummary: String? {
    var string = summary
    string = string?.replacingOccurrences(of: "\t", with: " ")
    string = string?.replacingOccurrences(of: "\n", with: "\n\n")
    return string
  }

  var formattedPeople: String? {
    people.map { person in person.name }.joined(separator: ", ")
  }

  var formattedDuration: String? {
    DateComponentsFormatter.duration.string(from: duration)
  }
}

extension Event: Hashable, Equatable {
  public static func == (lhs: Event, rhs: Event) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
