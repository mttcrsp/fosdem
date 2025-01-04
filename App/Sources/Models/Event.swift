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

  func isSameDay(as date: Date) -> Bool {
    guard let timezone = TimeZone(identifier: "Europe/Brussels") else {
      return false
    }

    let calendar = Calendar.gregorian
    let components1 = calendar.dateComponents(in: timezone, from: self.date)
    let components2 = calendar.dateComponents(in: timezone, from: date)

    return
      components1.month == components2.month &&
      components1.year == components2.year &&
      components1.day == components2.day
  }

  func isSameWeekday(as event: Event) -> Bool {
    let calendar = Calendar.gregorian
    let lhs = calendar.component(.weekday, from: date)
    let rhs = calendar.component(.weekday, from: event.date)
    return lhs == rhs
  }
}

extension Event {
  var formattedStart: String? {
    DateComponentsFormatter.time.string(from: start)
  }

  var formattedWeekday: String? {
    DateFormatter.weekday.string(from: date)
  }

  var formattedStartWithWeekday: String? {
    switch (formattedStart, formattedWeekday) {
    case (nil, _):
      nil
    case let (start?, nil):
      start
    case let (start?, weekday?):
      L10n.Search.Event.start(start, weekday)
    }
  }

  var formattedTrack: String {
    TrackFormatter().formattedName(from: track)
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

  var formattedDate: String? {
    var items: [String] = []

    if let start = formattedStart {
      items.append(start)
    }

    if let weekday = formattedWeekday {
      let string = L10n.Event.weekday(weekday)
      items.append(string)
    }

    if let duration = formattedDuration {
      let string = "(\(L10n.Event.duration(duration)))"
      items.append(string)
    }

    if items.isEmpty {
      return nil
    } else {
      return items.joined(separator: " ")
    }
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
