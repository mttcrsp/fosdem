@testable
import Fosdem
import XCTest

final class UbiquitousPreferencesServiceTests: XCTestCase {
  func testEditing() throws {
    let ubiquitousStore = UbiquitousPreferencesServiceStoreMock()
    let ubiquitousNotificationCenter = NotificationCenter()
    let service = UbiquitousPreferencesService(ubiquitousStore: ubiquitousStore, ubiquitousNotificationCenter: ubiquitousNotificationCenter)
    service.set("value", forKey: "key")
    XCTAssertEqual(ubiquitousStore.setArgValues.map(\.0) as? [String], ["value"])
    XCTAssertEqual(ubiquitousStore.setArgValues.map(\.1), ["key"])

    ubiquitousStore.objectHandler = { _ in "value" }
    XCTAssertEqual(service.value(forKey: "key") as? String, "value")
    XCTAssertEqual(ubiquitousStore.objectArgValues, ["key"])

    service.removeValue(forKey: "key")
    XCTAssertEqual(ubiquitousStore.removeObjectArgValues, ["key"])
  }

  func testSynchronize() {
    let ubiquitousStore = UbiquitousPreferencesServiceStoreMock()
    let ubiquitousNotificationCenter = NotificationCenter()
    let service = UbiquitousPreferencesService(ubiquitousStore: ubiquitousStore, ubiquitousNotificationCenter: ubiquitousNotificationCenter)
    service.startMonitoring()
    XCTAssertEqual(ubiquitousStore.synchronizeCallCount, 1)

    ubiquitousNotificationCenter.post(.init(name: UIApplication.willEnterForegroundNotification))
    XCTAssertEqual(ubiquitousStore.synchronizeCallCount, 2)

    service.stopMonitoring()
    ubiquitousNotificationCenter.post(.init(name: UIApplication.willEnterForegroundNotification))
    XCTAssertEqual(ubiquitousStore.synchronizeCallCount, 2)
  }

  func testExternalChanges() {
    let ubiquitousStore = UbiquitousPreferencesServiceStoreMock()
    let ubiquitousNotificationCenter = NotificationCenter()
    let service = UbiquitousPreferencesService(ubiquitousStore: ubiquitousStore, ubiquitousNotificationCenter: ubiquitousNotificationCenter)
    service.startMonitoring()

    var changedKeys: [String] = []
    let observer = service.addObserver { key in
      changedKeys.append(key)
    }

    let userInfo1: [String: Any] = [
      NSUbiquitousKeyValueStoreChangeReasonKey: NSUbiquitousKeyValueStoreInitialSyncChange,
      NSUbiquitousKeyValueStoreChangedKeysKey: ["key1", "key2"],
    ]
    let notification1 = Notification(name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, userInfo: userInfo1)
    ubiquitousNotificationCenter.post(notification1)
    XCTAssertEqual(changedKeys, ["key1", "key2"])

    let userInfo2: [String: Any] = [
      NSUbiquitousKeyValueStoreChangeReasonKey: NSUbiquitousKeyValueStoreServerChange,
      NSUbiquitousKeyValueStoreChangedKeysKey: ["key3"],
    ]
    let notification2 = Notification(name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, userInfo: userInfo2)
    ubiquitousNotificationCenter.post(notification2)
    XCTAssertEqual(changedKeys, ["key1", "key2", "key3"])

    service.removeObserver(observer)
    ubiquitousNotificationCenter.post(notification2)
    XCTAssertEqual(changedKeys, ["key1", "key2", "key3"])
  }
}
