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
      return nil
    case let (start?, nil):
      return start
    case let (start?, weekday?):
      return L10n.Search.Event.start(start, weekday)
    }
  }

  #if os(iOS)
  var formattedAbstract: String? {
    guard let abstract = abstract, let html = abstract.data(using: .utf8), let attributedString = try? NSAttributedString.fromHTML(html) else { return nil }

    var string = attributedString.string
    string = string.trimmingCharacters(in: .whitespacesAndNewlines)
    string = string.replacingOccurrences(of: "\t", with: " ")
    string = string.replacingOccurrences(of: "\n", with: "\n\n")
    return string
  }
  #endif

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
