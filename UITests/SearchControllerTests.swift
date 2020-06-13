import XCTest

final class SearchControllerTests: XCTestCase {
  private var app: XCUIApplication {
    XCUIApplication()
  }

  func testTracks() { // + sections + titles + index
    
  }

  func testTracksFavorites() {
    app.launch()
    app.searchButton.tap()

    while app.favoritesHeader.exists {
      let favoriteCell = app.tracksTable.cells.firstMatch
      favoriteCell.swipeLeft()
      favoriteCell.buttons["trailing0"].tap()
    }

    let favoriteCell1 = app.tracksTable.cells.element(boundBy: 0)
    let favoriteCell2 = app.tracksTable.cells.element(boundBy: 1)

    runActivity(named: "Unfavorite all from top") {
      for element in [app.day1TrackStaticText, app.day2TrackStaticText, favoriteCell1, favoriteCell1] {
        element.swipeLeft()
        app.buttons["trailing0"].tap()
      }
    }

    runActivity(named: "Unfavorite all from bottom") {
      for element in [app.day2TrackStaticText, app.day1TrackStaticText, favoriteCell2, favoriteCell1] {
        element.swipeLeft()
        app.buttons["trailing0"].tap()
      }
    }

    runActivity(named: "Unfavorite from non favorites section") {
      for _ in 1 ... 2 {
        let query = app.staticTexts.matching(identifier: "Ada")
        query.element(boundBy: query.count - 1).swipeLeft()
        app.buttons["trailing0"].tap()
      }
    }
  }

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
    let favoritesHeader = app.favoritesHeader

    while favoritesHeader.exists {
      let favoriteCell = app.tracksTable.cells.firstMatch
      favoriteCell.swipeLeft()
      favoriteCell.buttons["trailing0"].tap()
    }

    app.day2TrackStaticText.swipeLeft()
    app.buttons["trailing0"].tap()

    let filtersButton = app.buttons["filters"]
    let filterButtons = app.sheets["filters"].buttons

    // WORKAROUND: UIAlertAction does not support accessility identifiers.
    // This means that this test has to rely on index based queries to select
    // specific filter buttons.
    runActivity(named: "Select day 1") {
      filtersButton.tap()
      filterButtons.element(boundBy: 0).tap() // day 1
      XCTAssertTrue(day1Header.exists)
      XCTAssertFalse(favoritesHeader.exists)
      XCTAssertEqual(app.tracksTable.cells.count, 34)
    }

    runActivity(named: "Select day 2") {
      filtersButton.tap()
      filterButtons.element(boundBy: 1).tap() // day 2
      XCTAssertTrue(day2Header.exists)
      XCTAssertTrue(favoritesHeader.exists)
      XCTAssertEqual(app.tracksTable.cells.count, 38)
    }

    runActivity(named: "Select all") {
      filtersButton.tap()
      filterButtons.element(boundBy: 0).tap() // all
      XCTAssertTrue(allHeader.exists)
      XCTAssertTrue(favoritesHeader.exists)
      XCTAssertEqual(app.tracksTable.cells.count, 72)
    }
  }

  func testNavigateToTrack() {}
  func testNavigateToEvent() {}
  func testNavigateToResult() {}

  func testPopToRoot() {
    app.launch()
    app.searchButton.tap()

    runActivity(named: "Pop events") {
      app.day1TrackStaticText.tap()
      XCTAssertTrue(app.trackTable.exists)

      app.searchButton.tap()
      XCTAssertTrue(app.tracksTable.exists)
      XCTAssertFalse(app.trackTable.exists)
    }

    runActivity(named: "Pop event") {
      app.day1TrackStaticText.tap()
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
      app.day1TrackStaticText.tap()
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

  var day1TrackStaticText: XCUIElement {
    staticTexts["Ada"]
  }

  var day2TrackStaticText: XCUIElement {
    staticTexts["BSD"]
  }

  var trackTable: XCUIElement {
    tables["events"]
  }

  var eventStaticText: XCUIElement {
    staticTexts["Welcome to the Ada DevRoom"]
  }

  var eventTable: XCUIElement {
    tables["event"]
  }

  var welcomeView: XCUIElement {
    otherElements["welcome"]
  }

  var favoritesHeader: XCUIElement {
    otherElements["favorites"]
  }
}
