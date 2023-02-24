import XCTest

extension XCUIApplication {
  static var settings: XCUIApplication {
    XCUIApplication(bundleIdentifier: "com.apple.Preferences")
  }
}
