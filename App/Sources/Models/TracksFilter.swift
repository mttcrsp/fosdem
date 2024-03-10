import Foundation

enum TracksFilter: Equatable, Hashable {
  case all, day(Int)
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
    case let .day(day):
      L10n.Search.Filter.day(day)
    }
  }

  var accessibilityIdentifier: String {
    switch self {
    case .all:
      "all"
    case let .day(index):
      "day \(index)"
    }
  }
}
