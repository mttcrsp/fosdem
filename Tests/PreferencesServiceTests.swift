@testable
import Fosdem
import XCTest

final class PreferencesServiceTests: XCTestCase {
  func testEditing() throws {
    let userDefaultsDomain = "com.mttcrsp.test"
    let userDefaults = try XCTUnwrap(UserDefaults(suiteName: userDefaultsDomain))
    defer { userDefaults.removeSuite(named: userDefaultsDomain) }

    let notificationCenter = NotificationCenter()
    let preferencesService = PreferencesService(notificationCenter: notificationCenter, userDefaults: userDefaults)
    preferencesService.set("value", forKey: "key")
    XCTAssertEqual(preferencesService.value(forKey: "key") as? String, "value")

    preferencesService.removeValue(forKey: "key")
    XCTAssertNil(preferencesService.value(forKey: "key"))
  }

  func testObserver() throws {
    let userDefaultsDomain = "com.mttcrsp.test"
    let userDefaults = try XCTUnwrap(UserDefaults(suiteName: userDefaultsDomain))
    defer { userDefaults.removeSuite(named: userDefaultsDomain) }

    let notificationCenter = NotificationCenter()
    let preferencesService = PreferencesService(notificationCenter: notificationCenter, userDefaults: userDefaults)

    var callCount = 0
    let observer = preferencesService.addObserver(forKey: "key") {
      callCount += 1
    }

    preferencesService.set("value", forKey: "key")
    XCTAssertEqual(callCount, 1)
    preferencesService.set("value", forKey: "other")
    XCTAssertEqual(callCount, 1)
    preferencesService.removeValue(forKey: "key")
    XCTAssertEqual(callCount, 2)

    preferencesService.removeObserver(observer)
    preferencesService.set("value", forKey: "key")
    preferencesService.removeValue(forKey: "key")
    XCTAssertEqual(callCount, 2)
  }
}
