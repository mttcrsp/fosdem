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
      return NSLocalizedString("search.filter.all", comment: "")
    case let .day(day):
      let format = NSLocalizedString("search.filter.day", comment: "")
      let string = String(format: format, day)
      return string
    }
  }
}
