import XCTest

final class YearControllerTests: XCTestCase {
  private var _app: XCUIApplication!

  override func setUp() {
    super.setUp()
    _app = XCUIApplication()
    _app.launch()
    _app.moreButton.tap()
    _app.yearsCell.tap()
    _app.yearCell.tap()
  }

  func testTracks() {
    _app.cells["Ada"].tap()
    _app.staticTexts["Welcome to the Ada DevRoom"].tap()
    _app.backButton.tap()
    _app.backButton.tap()
  }

  func testSearch() {
    let cancelButton = _app.navigationBars.buttons.firstMatch
    let searchField = _app.searchFields.firstMatch

    searchField.tap()
    searchField.typeText("FOSDEM")
    _app.staticTexts["Welcome to FOSDEM 2019"].tap()
    _app.backButton.tap()
    cancelButton.tap()
    XCTAssert(_app.navigationBars["2019"].exists)
  }
}

private extension XCUIApplication {
  var yearsCell: XCUIElement {
    cells["years"]
  }

  var yearCell: XCUIElement {
    cells["2019"]
  }
}
