import XCTest

extension XCUIElement {
  func tapFirstTrailingAction() {
    swipeLeft()
    XCUIApplication().buttons["trailing0"].tap()
  }
}
