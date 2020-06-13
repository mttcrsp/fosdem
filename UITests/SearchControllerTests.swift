import XCTest

final class SearchControllerTests: XCTestCase {
  private var app: XCUIApplication {
    XCUIApplication()
  }

  func testTracksFavorites() {
    app.launch()
    app.searchButton.tap()

    while app.favoritesHeader.exists {
      let favoriteCell = app.tracksTable.cells.firstMatch
      favoriteCell.swipeLeft()
      favoriteCell.firstTrailingAction.tap()
    }

    let favoriteCell1 = app.tracksTable.cells.element(boundBy: 0)
    let favoriteCell2 = app.tracksTable.cells.element(boundBy: 1)

    runActivity(named: "Unfavorite all from top") {
      for element in [app.day1TrackStaticText, app.day2TrackStaticText, favoriteCell1, favoriteCell1] {
        element.swipeLeft()
        app.firstTrailingAction.tap()
      }
    }

    runActivity(named: "Unfavorite all from bottom") {
      for element in [app.day2TrackStaticText, app.day1TrackStaticText, favoriteCell2, favoriteCell1] {
        element.swipeLeft()
        app.firstTrailingAction.tap()
      }
    }

    runActivity(named: "Unfavorite from non favorites section") {
      for _ in 1 ... 2 {
        let query = app.staticTexts.matching(identifier: "Ada")
        query.element(boundBy: query.count - 1).swipeLeft()
        app.firstTrailingAction.tap()
      }
    }
  }

  func testTracksSectionIndexTitles() {
    app.launch()
    app.searchButton.tap()

    // WORKAROUND: UITableView does not provide access to its section index
    // view. This means that no accessility identifier can be set on said view.
    // This is why this test relies on the localized accessibility label for the
    // section index view and will break for different locales.
    let sectionIndex = app.tracksTable.otherElements["Section index"]
    let topSectionIndex = sectionIndex.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.01))
    let bottomSectionIndex = sectionIndex.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.99))
    let firstTrackStaticText = app.staticTexts["Ada"]
    let lastTrackStaticText = app.staticTexts["Workshops"]

    bottomSectionIndex.tap()
    XCTAssert(lastTrackStaticText.isHittable)

    topSectionIndex.tap()
    XCTAssert(firstTrackStaticText.isHittable)
  }

  func testTrack() {
    app.launch()
    app.searchButton.tap()

    while app.favoritesHeader.exists {
      let favoriteCell = app.tracksTable.cells.firstMatch
      favoriteCell.swipeLeft()
      favoriteCell.firstTrailingAction.tap()
    }

    let favoriteTrackButton = app.buttons["favorite"]
    let unfavoriteTrackButton = app.buttons["unfavorite"]

    runActivity(named: "Favorite from search") {
      app.day1TrackStaticText.swipeLeft()
      app.firstTrailingAction.tap()
      app.tracksTable.cells.firstMatch.tap()
      XCTAssert(unfavoriteTrackButton.exists)
    }

    runActivity(named: "Display track") {
      XCTAssert(app.eventHeaderStaticText.exists)
      XCTAssertEqual(app.trackTable.cells.count, 15)
    }

    runActivity(named: "Unfavorite from track") {
      unfavoriteTrackButton.tap()
      XCTAssert(favoriteTrackButton.exists)

      app.searchButton.tap()
      XCTAssertEqual(app.tracksTable.cells.count, 71)
    }

    runActivity(named: "Favorite from track") {
      app.day1TrackStaticText.tap()
      favoriteTrackButton.tap()
      XCTAssert(unfavoriteTrackButton.exists)

      app.searchButton.tap()
      XCTAssertEqual(app.tracksTable.cells.count, 72)
    }

    runActivity(named: "Unfavorite from search") {
      app.tracksTable.cells.firstMatch.swipeLeft()
      app.firstTrailingAction.tap()
      app.day1TrackStaticText.tap()
      XCTAssert(favoriteTrackButton.exists)
    }
  }

  func testFavoriteEvent() {}
  func testUnfavoriteEvent() {}

  func testSearch() {
    app.launch()
    app.searchButton.tap()

    while app.favoritesHeader.exists {
      let favoriteCell = app.tracksTable.cells.firstMatch
      favoriteCell.swipeLeft()
      favoriteCell.firstTrailingAction.tap()
    }

    let unfavoriteButton = app.buttons["unfavorite"]
    let favoriteButton = app.buttons["favorite"]
    let resultsCells = app.tables["events"].cells
    let cell = resultsCells.firstMatch

    runActivity(named: "Display results") {
      let searchBar = app.searchFields.firstMatch
      searchBar.tap()
      searchBar.typeText("javascript symphonies")
      XCTAssertEqual(resultsCells.count, 1)
      XCTAssert(app.staticTexts["JavaScript"].exists)
      XCTAssert(app.staticTexts["Creating symphonies in JavaScript"].exists)
    }

    runActivity(named: "Favorite event") {
      cell.swipeLeft()
      app.firstTrailingAction.tap()
      cell.tap()
      XCTAssert(unfavoriteButton.exists)
    }

    runActivity(named: "Unfavorite event") {
      app.navigationBars.buttons.firstMatch.tap()
      cell.swipeLeft()
      app.firstTrailingAction.tap()
      cell.tap()
      XCTAssert(favoriteButton.exists)
    }
  }

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
      favoriteCell.firstTrailingAction.tap()
    }

    app.day2TrackStaticText.swipeLeft()
    app.firstTrailingAction.tap()

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

private extension XCUIApplication {
  var searchButton: XCUIElement {
    tabBars.buttons["search"]
  }

  var tracksTable: XCUIElement {
    tables["tracks"]
  }

  var day1TrackStaticText: XCUIElement {
    tracksTable.staticTexts["Ada"]
  }

  var day2TrackStaticText: XCUIElement {
    tracksTable.staticTexts["BSD"]
  }

  var trackTable: XCUIElement {
    tables["events"]
  }

  var eventHeaderStaticText: XCUIElement {
    trackTable.staticTexts["10:35"]
  }

  var eventStaticText: XCUIElement {
    trackTable.staticTexts["Welcome to the Ada DevRoom"]
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

extension XCUIElement {
  var firstTrailingAction: XCUIElement {
    buttons["trailing0"]
  }
}
