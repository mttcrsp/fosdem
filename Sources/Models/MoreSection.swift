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

  var title: String? {
    switch self {
    case .years:
      return FOSLocalizedString("more.section.years")
    case .recent:
      return FOSLocalizedString("more.section.recent")
    case .about:
      return FOSLocalizedString("more.section.about")
    case .other:
      return FOSLocalizedString("more.section.other")
    #if DEBUG
    case .debug:
      return "Debug"
    #endif
    }
  }
}
