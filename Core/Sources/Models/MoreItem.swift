enum MoreItem: String, CaseIterable {
  #if DEBUG
  case time
  #endif

  case code
  case legal
  case years
  case video
  case history
  case devrooms
  case transportation
  case acknowledgements
}

extension MoreItem {
  var info: Info? {
    switch self {
    case .legal:
      return .legal
    case .history:
      return .history
    case .devrooms:
      return .devrooms
    case .transportation:
      return .transportation
    case .code, .years, .video, .acknowledgements:
      return nil
    #if DEBUG
    case .time:
      return nil
    #endif
    }
  }

  var accessibilityIdentifier: String {
    rawValue
  }
}
