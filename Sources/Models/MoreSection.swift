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
      return [.code, .acknowledgements]
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
      return NSLocalizedString("more.section.years", comment: "")
    case .about:
      return NSLocalizedString("more.section.about", comment: "")
    case .other:
      return NSLocalizedString("more.section.other", comment: "")
    }
  }
}
