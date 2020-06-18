import XCTest

final class YearControllerTests: XCTestCase {
  private var app: XCUIApplication!

  override func setUp() {
    super.setUp()
    app = XCUIApplication()
    app.launch()
    app.moreButton.tap()
    app.yearsCell.tap()
    app.yearCell.tap()
  }

  func testTracks() {
    app.cells["Ada"].tap()
    app.staticTexts["Welcome to the Ada DevRoom"].tap()
    app.backButton.tap()
    app.backButton.tap()
  }

  func testSearch() {
    let cancelButton = app.navigationBars.buttons.firstMatch
    let searchField = app.searchFields.firstMatch

    searchField.tap()
    searchField.typeText("FOSDEM")
    app.staticTexts["Welcome to FOSDEM 2019"].tap()
    app.backButton.tap()
    cancelButton.tap()
    XCTAssert(app.navigationBars["2019"].exists)
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
