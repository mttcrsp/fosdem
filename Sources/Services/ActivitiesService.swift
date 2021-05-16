import UIKit

protocol Activity: Codable {
  static var activityType: String { get }
}

extension Activity {
  func makeUserActivity() -> NSUserActivity? {
    do {
      let encoded = try PropertyListEncoder().encode(self)
      let decoded = try PropertyListSerialization.propertyList(from: encoded, format: nil) as? [String: Any]
      let userActivity = NSUserActivity(activityType: Self.activityType)
      userActivity.addUserInfoEntries(from: decoded ?? [:])
      return userActivity
    } catch {
      assertionFailure(error.localizedDescription)
      return nil
    }
  }

  static func make(from userActivity: NSUserActivity) -> Self? {
    guard userActivity.activityType == Self.activityType else {
      return nil
    }

    do {
      let info = userActivity.userInfo ?? [:]
      let data = try PropertyListSerialization.data(fromPropertyList: info, format: .binary, options: 0)
      return try PropertyListDecoder().decode(Self.self, from: data)
    } catch {
      assertionFailure(error.localizedDescription)
      return nil
    }
  }
}

final class ActivitiesService {
  func makeViewController(for userActivity: NSUserActivity) -> UIViewController? {
    guard let content = makeContent(from: userActivity) else { return nil }

    let alertAction = UIAlertAction(title: L10n.Error.dismiss, style: .cancel)
    let alertController = UIAlertController(title: content.title, message: content.message, preferredStyle: .alert)
    alertController.addAction(alertAction)
    return alertController
  }

  private struct Content {
    let title: String
    let message: String?
  }

  private func makeContent(from userActivity: NSUserActivity) -> Content? {
    if let playVideo = PlayVideo.make(from: userActivity) {
      return Content(title: type(of: playVideo).activityType, message: playVideo.event.title)
    } else if let readAttachment = ReadAttachment.make(from: userActivity) {
      return Content(title: type(of: readAttachment).activityType, message: readAttachment.event.title)
    } else if let readTransportation = ReadTransportation.make(from: userActivity) {
      return Content(title: type(of: readTransportation).activityType, message: readTransportation.item.title)
    } else {
      return nil
    }
  }
}
