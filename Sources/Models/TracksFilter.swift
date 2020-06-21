import Foundation

enum TracksFilter: Equatable, Hashable {
  case all, day(Int)
}

extension TracksFilter: Comparable {
  static func < (lhs: TracksFilter, rhs: TracksFilter) -> Bool {
    switch (lhs, rhs) {
    case (.all, _):
      return true
    case (.day, .all):
      return false
    case let (.day(lhs), .day(rhs)):
      return lhs < rhs
    }
  }
}

extension TracksFilter {
  var title: String {
    switch self {
    case .all:
      return FOSLocalizedString("search.filter.all")
    case let .day(day):
      return FOSLocalizedString(format: "search.filter.day", day)
    }
  }

  var accessibilityIdentifier: String {
    switch self {
    case .all:
      return "all"
    case let .day(index):
      return "day \(index)"
    }
  }
}
