import Foundation

enum MoreSection: CaseIterable {
  case years
  case about
  case other
  #if DEBUG
  case debug
  #endif
}

extension MoreSection {
  var items: [MoreItem] {
    switch self {
    #if DEBUG
    case .debug:
      return [.time]
    #endif
    case .years:
      return [.years]
    case .other:
      return [.code, .acknowledgements, .legal]
    case .about:
      return [.history, .devrooms, .transportation]
    }
  }

  var title: String? {
    switch self {
    #if DEBUG
    case .debug:
      return "Debug"
    #endif
    case .years:
      return FOSLocalizedString("more.section.years")
    case .about:
      return FOSLocalizedString("more.section.about")
    case .other:
      return FOSLocalizedString("more.section.other")
    }
  }
}
