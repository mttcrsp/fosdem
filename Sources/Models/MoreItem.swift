import UIKit

enum MoreItem: String, CaseIterable {
  #if DEBUG
  case time
  #endif

  case code
  case legal
  case years
  case history
  case devrooms
  case transportation
  case acknowledgements
}

extension MoreItem {
  var title: String {
    switch self {
    case .code:
      return FOSLocalizedString("code.title")
    case .legal:
      return FOSLocalizedString("legal.title")
    case .years:
      return FOSLocalizedString("years.item")
    case .history:
      return FOSLocalizedString("history.title")
    case .devrooms:
      return FOSLocalizedString("devrooms.title")
    case .transportation:
      return FOSLocalizedString("transportation.title")
    case .acknowledgements:
      return FOSLocalizedString("acknowledgements.title")
    #if DEBUG
    case .time:
      return "Override current time"
    #endif
    }
  }

  var icon: UIImage? {
    switch self {
    case .code:
      return UIImage(named: "contribute")
    case .legal:
      return UIImage(named: "document")
    case .years:
      return UIImage(named: "years")
    case .history:
      return UIImage(named: "history")
    case .devrooms:
      return UIImage(named: "devrooms")
    case .transportation:
      return UIImage(named: "transportation")
    case .acknowledgements:
      return UIImage(named: "document")
    #if DEBUG
    case .time:
      return nil
    #endif
    }
  }

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
    case .code, .years, .acknowledgements:
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
