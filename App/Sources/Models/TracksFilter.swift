import Foundation

enum TracksFilter: Equatable, Hashable {
  case all, day(Date)
}

extension TracksFilter: Comparable {
  static func < (lhs: TracksFilter, rhs: TracksFilter) -> Bool {
    switch (lhs, rhs) {
    case (.all, _):
      true
    case (.day, .all):
      false
    case let (.day(lhs), .day(rhs)):
      lhs < rhs
    }
  }
}

extension TracksFilter {
  var title: String {
    switch self {
    case .all:
      L10n.Search.Filter.all
    case let .day(date):
      DateFormatter.weekdayWithShortDate.string(from: date)
    }
  }

  var action: String {
    switch self {
    case .all:
      L10n.Search.Filter.Menu.Action.all
    case let .day(date):
      L10n.Search.Filter.Menu.Action.day(DateFormatter.weekday.string(from: date))
    }
  }

  var accessibilityIdentifier: String {
    switch self {
    case .all:
      "all"
    case let .day(date):
      "\(date)"
    }
  }
}
