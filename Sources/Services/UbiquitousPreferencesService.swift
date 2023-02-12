import Foundation

final class UbiquitousPreferencesService {
  private let notificationCenter = NotificationCenter()
  private let ubiquitousStore: UbiquitousPreferencesServiceStore
  private let ubiquitousNotificationCenter: NotificationCenter
  private var ubiquitousObserver: NSObjectProtocol?

  init(ubiquitousStore: UbiquitousPreferencesServiceStore = NSUbiquitousKeyValueStore.default, ubiquitousNotificationCenter: NotificationCenter = .default) {
    self.ubiquitousStore = ubiquitousStore
    self.ubiquitousNotificationCenter = ubiquitousNotificationCenter
  }

  func set(_ value: Any?, forKey key: String) {
    ubiquitousStore.set(value, forKey: key)
  }

  func value(forKey key: String) -> Any? {
    ubiquitousStore.object(forKey: key)
  }

  func removeValue(forKey key: String) {
    ubiquitousStore.removeObject(forKey: key)
  }

  func addObserver(_ handler: @escaping (String) -> Void) -> NSObjectProtocol {
    notificationCenter.addObserver(forName: .didChangeValue, object: nil, queue: nil) { notification in
      if let changedKeys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] {
        for key in changedKeys {
          handler(key)
        }
      }
    }
  }

  func removeObserver(_ observer: NSObjectProtocol) {
    notificationCenter.removeObserver(observer)
  }

  func startMonitoring() {
    guard ubiquitousObserver == nil else {
      return assertionFailure("Attempted to start monitoring on already active ubiquitous preferences service \(self)")
    }

    ubiquitousObserver = ubiquitousNotificationCenter.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: nil, queue: nil) { [weak self] notification in
      self?.didChangeExternally(notification)
    }
    ubiquitousStore.synchronize()
  }

  func stopMonitoring() {
    guard let observer = ubiquitousObserver else {
      return assertionFailure("Attempted to stop monitoring on inactive ubiquitous preferences service \(self)")
    }

    ubiquitousNotificationCenter.removeObserver(observer)
  }

  private func didChangeExternally(_ notification: Notification) {
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

protocol UbiquitousPreferencesServiceProtocol {
  func set(_ value: Any?, forKey key: String)
  func value(forKey key: String) -> Any?
  func removeValue(forKey key: String)

  func addObserver(_ handler: @escaping (String) -> Void) -> NSObjectProtocol
  func removeObserver(_ observer: NSObjectProtocol)

  func startMonitoring()
  func stopMonitoring()
}

extension UbiquitousPreferencesService: UbiquitousPreferencesServiceProtocol {}
