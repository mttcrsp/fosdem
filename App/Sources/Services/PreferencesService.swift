import Foundation

struct PreferencesService {
  var set: (Any?, String) -> Void
  var value: (String) -> Any?
  var removeValue: (String) -> Void

  var addObserver: (String, @escaping () -> Void) -> NSObjectProtocol
  var removeObserver: (NSObjectProtocol) -> Void
}

extension PreferencesService {
  init(notificationCenter: NotificationCenter = .default, userDefaults: UserDefaults = .standard) {
    set = { value, key in
      userDefaults.set(value, forKey: key)

      let notification = Notification(name: .didChangeValue, userInfo: ["key": key])
      notificationCenter.post(notification)
    }

    value = { key in
      userDefaults.object(forKey: key)
    }

    removeValue = { key in
      userDefaults.removeObject(forKey: key)

      let notification = Notification(name: .didChangeValue, userInfo: ["key": key])
      notificationCenter.post(notification)
    }

    addObserver = { key, handler in
      notificationCenter.addObserver(forName: .didChangeValue, object: nil, queue: .main) { notification in
        if let changedKey = notification.userInfo?["key"] as? String, changedKey == key {
          handler()
        }
      }
    }

    removeObserver = { observer in
      notificationCenter.removeObserver(observer)
    }
  }
}

private extension Notification.Name {
  static let didChangeValue = NSNotification.Name("com.mttcrsp.ansia.PreferencesService.didChangeValue")
}

/// @mockable
protocol PreferencesServiceProtocol {
  var set: (Any?, String) -> Void { get }
  var value: (String) -> Any? { get }
  var removeValue: (String) -> Void { get }

  var addObserver: (String, @escaping () -> Void) -> NSObjectProtocol { get }
  var removeObserver: (NSObjectProtocol) -> Void { get }
}

extension PreferencesService: PreferencesServiceProtocol {}
