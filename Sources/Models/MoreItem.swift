import UIKit

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
  var title: String {
    switch self {
    case .code:
      return L10n.Code.title
    case .legal:
      return L10n.Legal.title
    case .years:
      return L10n.Years.item
    case .video:
      return L10n.Recent.video
    case .history:
      return L10n.History.title
    case .devrooms:
      return L10n.Devrooms.title
    case .transportation:
      return L10n.Transportation.title
    case .acknowledgements:
      return L10n.Acknowledgements.title
    #if DEBUG
    case .time:
      return "Override current time"
    #endif
    }
  }

  var icon: UIImage? {
    switch self {
    case .code:
      return Asset.More.contribute.image
    case .legal:
      return Asset.More.document.image
    case .years:
      return Asset.More.years.image
    case .video:
      return Asset.More.video.image
    case .history:
      return Asset.More.history.image
    case .devrooms:
      return Asset.More.devrooms.image
    case .transportation:
      return Asset.More.transportation.image
    case .acknowledgements:
      return Asset.More.document.image
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
