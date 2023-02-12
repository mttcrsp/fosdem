import Foundation

final class PreferencesService {
  private let notificationCenter: NotificationCenter
  private let userDefaults: UserDefaults

  init(notificationCenter: NotificationCenter = .default, userDefaults: UserDefaults = .standard) {
    self.notificationCenter = notificationCenter
    self.userDefaults = userDefaults
  }

  func set(_ value: Any?, forKey key: String) {
    userDefaults.set(value, forKey: key)

    let notification = Notification(name: .didChangeValue, userInfo: ["key": key])
    notificationCenter.post(notification)
  }

  func value(forKey key: String) -> Any? {
    userDefaults.object(forKey: key)
  }

  func removeValue(forKey key: String) {
    userDefaults.removeObject(forKey: key)

    let notification = Notification(name: .didChangeValue, userInfo: ["key": key])
    notificationCenter.post(notification)
  }

  func addObserver(forKey key: String, using handler: @escaping () -> Void) -> NSObjectProtocol {
    notificationCenter.addObserver(forName: .didChangeValue, object: nil, queue: nil) { notification in
      if let changedKey = notification.userInfo?["key"] as? String, changedKey == key {
        handler()
      }
    }
  }

  func removeObserver(_ observer: NSObjectProtocol) {
    notificationCenter.removeObserver(observer)
  }
}

private extension Notification.Name {
  static let didChangeValue = NSNotification.Name("com.mttcrsp.ansia.PreferencesService.didChangeValue")
}

/// @mockable
protocol PreferencesServiceProtocol {
  func set(_ value: Any?, forKey key: String)
  func value(forKey key: String) -> Any?
  func removeValue(forKey key: String)

  func addObserver(forKey key: String, using handler: @escaping () -> Void) -> NSObjectProtocol
  func removeObserver(_ observer: NSObjectProtocol)
}

extension PreferencesService: PreferencesServiceProtocol {}
