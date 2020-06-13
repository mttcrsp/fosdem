import XCTest

final class SearchControllerTests: XCTestCase {
  private var app: XCUIApplication {
    XCUIApplication()
  }

  func testTracks() {} // + sections + titles + index
  func testFavoriteTrack() {}
  func testUnfavoriteTrack() {}

  func testEvents() {} // (+ captions)
  func testFavoriteEvent() {}
  func testUnfavoriteEvent() {}

  func testSearch() {}

  func testFilters() {
    app.launch()
    app.searchButton.tap()

    let allHeader = app.otherElements["all"]
    let day1Header = app.otherElements["day 1"]
    let day2Header = app.otherElements["day 2"]
    let favoritesHeader = app.otherElements["favorites"]

    while favoritesHeader.exists {
      let favoriteCell = app.tracksTable.cells.firstMatch
      favoriteCell.swipeLeft()
      favoriteCell.buttons["trailing0"].tap()
    }

    let dayTwoTrackStaticText = app.staticTexts["BSD"]
    dayTwoTrackStaticText.swipeLeft()
    app.buttons["trailing0"].tap()

    let filtersButton = app.buttons["filters"]
    let filterButtons = app.sheets["filters"].buttons

    // WORKAROUND: UIAlertAction does not support accessility identifiers.
    // This means that this test has to rely on index based queries to select
    // specific filter buttons.
    filtersButton.tap()
    filterButtons.element(boundBy: 0).tap() // day 1
    XCTAssertTrue(day1Header.exists)
    XCTAssertFalse(favoritesHeader.exists)
    XCTAssertEqual(app.tracksTable.cells.count, 34)

    filtersButton.tap()
    filterButtons.element(boundBy: 1).tap() // day 2
    XCTAssertTrue(day2Header.exists)
    XCTAssertTrue(favoritesHeader.exists)
    XCTAssertEqual(app.tracksTable.cells.count, 38)

    filtersButton.tap()
    filterButtons.element(boundBy: 0).tap() // all
    XCTAssertTrue(allHeader.exists)
    XCTAssertTrue(favoritesHeader.exists)
    XCTAssertEqual(app.tracksTable.cells.count, 72)
  }

  func testNavigateToTrack() {}
  func testNavigateToEvent() {}
  func testNavigateToResult() {}

  func testPopToRoot() {
    app.launch()
    app.searchButton.tap()

    runActivity(named: "Pop events") {
      app.trackStaticText.tap()
      XCTAssertTrue(app.trackTable.exists)

      app.searchButton.tap()
      XCTAssertTrue(app.tracksTable.exists)
      XCTAssertFalse(app.trackTable.exists)
    }

    runActivity(named: "Pop event") {
      app.trackStaticText.tap()
      app.eventStaticText.tap()
      XCTAssertTrue(app.eventTable.exists)

      app.searchButton.tap()
      XCTAssertTrue(app.tracksTable.exists)
      XCTAssertFalse(app.eventTable.exists)
    }
  }

  func testCollapseExpand() {
    let app = self.app
    XCUIDevice.shared.orientation = .portrait

    runActivity(named: "Handle welcome") {
      app.searchButton.tap()
      app.launch()
      wait { app.tracksTable.exists }
      wait { !app.welcomeView.exists }

      XCUIDevice.shared.orientation = .landscapeLeft
      wait { app.tracksTable.exists }
      wait { app.welcomeView.exists }

      XCUIDevice.shared.orientation = .portrait
      wait { app.tracksTable.exists }
      wait { !app.welcomeView.exists }
    }

    runActivity(named: "Handle others") {
      app.trackStaticText.tap()
      wait { app.trackTable.exists }
      wait { !app.tracksTable.exists }

      XCUIDevice.shared.orientation = .landscapeRight
      wait { app.trackTable.exists }
      wait { app.tracksTable.exists }
      
      app.eventStaticText.tap()
      wait { app.eventTable.exists }
      wait { app.tracksTable.exists }
      wait { !app.trackTable.exists }

      XCUIDevice.shared.orientation = .portrait
      wait { app.eventTable.exists }
      wait { !app.trackTable.exists }
      wait { !app.tracksTable.exists }
    }
  }
}

extension XCTestCase {
  func runActivity(named: String, block: () -> Void) {
    XCTContext.runActivity(named: named) { _ in block() }
  }

  func wait(for predicate: @escaping () -> Bool, timeout: TimeInterval = 3) {
    let predicate = NSPredicate { _, _ in predicate() }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    XCTWaiter().wait(for: [expectation], timeout: timeout)
  }
}

private extension XCUIApplication {
  var searchButton: XCUIElement {
    tabBars.buttons["search"]
  }

  var tracksTable: XCUIElement {
    tables["tracks"]
  }

  var trackStaticText: XCUIElement {
    staticTexts[trackName]
  }

  var trackTable: XCUIElement {
    tables["events"]
  }

  var eventStaticText: XCUIElement {
    staticTexts[eventTitle]
  }

  var eventTable: XCUIElement {
    tables["event"]
  }

  var welcomeView: XCUIElement {
    otherElements["welcome"]
  }

  private var trackName: String {
    "Ada"
  }

  private var eventTitle: String {
    "Welcome to the Ada DevRoom"
  }
}
