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
      return [.overrideTime, .generateDatabase]
    #endif
    }
  }

  var title: String? {
    switch self {
    case .years:
      return L10n.More.Section.years
    case .recent:
      return L10n.More.Section.recent
    case .about:
      return L10n.More.Section.about
    case .other:
      return L10n.More.Section.other
    #if DEBUG
    case .debug:
      return "Debug"
    #endif
    }
  }
}
