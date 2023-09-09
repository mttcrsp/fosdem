import UIKit

struct UbiquitousPreferencesService {
  var set: (Any?, String) -> Void
  var value: (String) -> Any?
  var removeValue: (String) -> Void

  var addObserver: (@escaping (String) -> Void) -> NSObjectProtocol
  var removeObserver: (NSObjectProtocol) -> Void

  var startMonitoring: () -> Void
  var stopMonitoring: () -> Void
}

extension UbiquitousPreferencesService {
  init(ubiquitousStore: UbiquitousPreferencesServiceStore = NSUbiquitousKeyValueStore.default, ubiquitousNotificationCenter: NotificationCenter = .default) {
    let notificationCenter = NotificationCenter()

    var ubiquitousObservers: [NSObjectProtocol] = []

    func didChangeExternally(_ notification: Notification) {
      guard let userInfo = notification.userInfo,
            let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int,
            let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else { return }

      switch reason {
      case NSUbiquitousKeyValueStoreServerChange, NSUbiquitousKeyValueStoreInitialSyncChange:
        let notificationUserInfo = [NSUbiquitousKeyValueStoreChangedKeysKey: changedKeys]
        let notification = Notification(name: .didChangeValue, userInfo: notificationUserInfo)
        notificationCenter.post(notification)
      case NSUbiquitousKeyValueStoreAccountChange:
        break
      case NSUbiquitousKeyValueStoreQuotaViolationChange:
        assertionFailure("iCloud Key-Value storage quota exceeded")
      default:
        assertionFailure("Unknown NSUbiquitousKeyValueStore.didChangeExternallyNotification notification received with reason '\(reason)'")
      }
    }

    set = { value, key in
      ubiquitousStore.set(value, forKey: key)
    }

    value = { key in
      ubiquitousStore.object(forKey: key)
    }

    removeValue = { key in
      ubiquitousStore.removeObject(forKey: key)
    }

    addObserver = { handler in
      notificationCenter.addObserver(forName: .didChangeValue, object: nil, queue: .main) { notification in
        if let changedKeys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] {
          for key in changedKeys {
            handler(key)
          }
        }
      }
    }

    removeObserver = { observer in
      notificationCenter.removeObserver(observer)
    }

    startMonitoring = {
      guard ubiquitousObservers.isEmpty else {
        return assertionFailure("Attempted to start monitoring on already active ubiquitous preferences service")
      }

      ubiquitousObservers = [
        ubiquitousNotificationCenter.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: nil, queue: nil) { notification in
          didChangeExternally(notification)
        },
        ubiquitousNotificationCenter.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { _ in
          ubiquitousStore.synchronize()
        },
      ]
      ubiquitousStore.synchronize()
    }

    stopMonitoring = {
      guard !ubiquitousObservers.isEmpty else {
        return assertionFailure("Attempted to stop monitoring on inactive ubiquitous preferences service")
      }

      for observer in ubiquitousObservers {
        ubiquitousNotificationCenter.removeObserver(observer)
      }
    }
  }
}

private extension Notification.Name {
  static let didChangeValue = NSNotification.Name("com.mttcrsp.ansia.UbiquitousPreferencesService.didChangeValue")
}

/// @mockable
protocol UbiquitousPreferencesServiceStore {
  @discardableResult
  func synchronize() -> Bool
  func set(_ anObject: Any?, forKey aKey: String)
  func object(forKey aKey: String) -> Any?
  func removeObject(forKey aKey: String)
}

extension NSUbiquitousKeyValueStore: UbiquitousPreferencesServiceStore {}

/// @mockable
protocol UbiquitousPreferencesServiceProtocol {
  var set: (Any?, String) -> Void { get }
  var value: (String) -> Any? { get }
  var removeValue: (String) -> Void { get }

  var addObserver: (@escaping (String) -> Void) -> NSObjectProtocol { get }
  var removeObserver: (NSObjectProtocol) -> Void { get }

  var startMonitoring: () -> Void { get }
  var stopMonitoring: () -> Void { get }
}

extension UbiquitousPreferencesService: UbiquitousPreferencesServiceProtocol {}

protocol HasUbiquitousPreferencesService {
  var ubiquitousPreferencesService: UbiquitousPreferencesServiceProtocol { get }
}
