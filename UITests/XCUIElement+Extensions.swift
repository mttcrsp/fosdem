import XCTest

extension XCUIElement {
  var backButton: XCUIElement {
    navigationBars.buttons.firstMatch
  }

  func tapFirstTrailingAction() {
    swipeLeft()
    XCUIApplication().buttons["trailing0"].tap()
  }
}
