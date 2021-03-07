extension TracksFilter {
  var title: String {
    switch self {
    case .all:
      return L10n.Search.Filter.all
    case let .day(day):
      return L10n.Search.Filter.day(day)
    }
  }
}
