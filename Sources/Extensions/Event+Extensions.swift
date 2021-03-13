import L10n
import Schedule
import UIKit

public extension Event {
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
}
