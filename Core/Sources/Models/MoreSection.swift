import Foundation

enum MoreSection: CaseIterable {
  case years
  case about
  case recent
  case other
  #if DEBUG
  case debug
  #endif
}

extension MoreSection {
  var items: [MoreItem] {
    switch self {
    case .years:
      return [.years]
    case .recent:
      return [.video]
    case .other:
      return [.code, .acknowledgements, .legal]
    case .about:
      return [.history, .devrooms, .transportation]
    #if DEBUG
    case .debug:
      return [.time]
    #endif
    }
  }
}
