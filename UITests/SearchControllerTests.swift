import XCTest

final class SearchControllerTests: XCTestCase {
  func testTracksFavorites() {
    let app = XCUIApplication()
    app.launchEnvironment = ["RESET_DEFAULTS": "1"]
    app.launch()
    app.searchButton.tap()

    let favoriteCell1 = app.tracksTable.cells.element(boundBy: 0)
    let favoriteCell2 = app.tracksTable.cells.element(boundBy: 1)

    runActivity(named: "Unfavorite all from top") {
      for element in [app.day1TrackCell, app.day2TrackCell] {
        element.tapTrailingAction(withIdentifier: "Favorite")
      }

      for element in [favoriteCell1, favoriteCell1] {
        element.tapTrailingAction(withIdentifier: "Unfavorite")
      }
    }

    runActivity(named: "Unfavorite all from bottom") {
      for element in [app.day1TrackCell, app.day2TrackCell] {
        element.tapTrailingAction(withIdentifier: "Favorite")
      }

      for element in [favoriteCell2, favoriteCell1] {
        element.tapTrailingAction(withIdentifier: "Unfavorite")
      }
    }

    runActivity(named: "Unfavorite from non favorites section") {
      let query = app.cells.matching(identifier: app.day1TrackCellIdentifier)
      var element = query.element(boundBy: query.count - 1)
      element.tapTrailingAction(withIdentifier: "Favorite")
      element = query.element(boundBy: query.count - 1)
      element.tapTrailingAction(withIdentifier: "Unfavorite")
    }
  }

  func testTracksSectionIndexTitles() {
    let app = XCUIApplication()
    app.launch()
    app.searchButton.tap()

    // WORKAROUND: UITableView does not provide access to its section index
    // view. This means that no accessility identifier can be set on said view.
    // This is why this test relies on the localized accessibility label for the
    // section index view and will break for different locales.
    let sectionIndex = app.tracksTable.otherElements["Section index"]
    let topSectionIndex = sectionIndex.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.01))
    let bottomSectionIndex = sectionIndex.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.99))
    let firstTrackStaticText = app.staticTexts["BSD"]
    let lastTrackStaticText = app.staticTexts["Zig Programming Language"]

    bottomSectionIndex.tap()
    XCTAssert(lastTrackStaticText.isHittable)

    topSectionIndex.tap()
    XCTAssert(firstTrackStaticText.isHittable)
  }

  func testTrack() {
    let app = XCUIApplication()
    app.launchEnvironment = ["RESET_DEFAULTS": "1"]
    app.launch()
    app.searchButton.tap()

    let favoriteTrackButton = app.buttons["favorite"]
    let unfavoriteTrackButton = app.buttons["unfavorite"]

    runActivity(named: "Favorite from search") {
      app.day1TrackCell.tapTrailingAction(withIdentifier: "Favorite")
      app.tracksTable.cells.firstMatch.tap()
      XCTAssert(unfavoriteTrackButton.exists)
    }

    runActivity(named: "Display track") {
      XCTAssert(app.trackTable.staticTexts["11:00"].exists)
      XCTAssertEqual(app.trackTable.cells.count, 10)
    }

    let tracksCount = 38

    runActivity(named: "Unfavorite from track") {
      unfavoriteTrackButton.tap()
      XCTAssert(favoriteTrackButton.exists)

      app.searchButton.tap()
      XCTAssertEqual(app.tracksTable.cells.count, tracksCount)
    }

    runActivity(named: "Favorite from track") {
      app.day1TrackCell.tap()
      favoriteTrackButton.tap()
      XCTAssert(unfavoriteTrackButton.exists)

      app.searchButton.tap()
      XCTAssertEqual(app.tracksTable.cells.count, tracksCount + 1)
    }

    runActivity(named: "Unfavorite from search") {
      app.tracksTable.cells.firstMatch.tapTrailingAction(withIdentifier: "Unfavorite")
      app.day1TrackCell.tap()
      XCTAssert(favoriteTrackButton.exists)
    }
  }

  func testSearch() {
    let app = XCUIApplication()
    app.launchEnvironment = ["RESET_DEFAULTS": "1"]
    app.launch()
    app.searchButton.tap()

    let resultsCells = app.tables["events"].cells
    let cell = resultsCells.firstMatch

    runActivity(named: "Display results") {
      let searchBar = app.searchFields.firstMatch
      searchBar.tap()
      searchBar.typeText("javascript learning")
      XCTAssertEqual(resultsCells.count, 1)
      XCTAssert(app.staticTexts["JavaScript"].exists)
      XCTAssert(app.staticTexts["Reinforcement Learning with JavaScript"].exists)
    }

    runActivity(named: "Favorite event") {
      cell.tapTrailingAction(withIdentifier: "Add to Agenda")
      cell.tap()
      wait { app.unfavoriteEventButton.exists }
    }

    runActivity(named: "Unfavorite event") {
      app.backButton.tap()
      cell.tapTrailingAction(withIdentifier: "Remove from Agenda")
      cell.tap()
      wait { app.favoriteEventButton.exists }
    }
  }

  func testFilters() {
    let app = XCUIApplication()
    app.launchEnvironment = ["RESET_DEFAULTS": "1"]
    app.launch()
    app.searchButton.tap()

    let allHeader = app.otherElements["all"]
    let day1Header = app.otherElements["day 1"]
    let day2Header = app.otherElements["day 2"]
    let favoritesHeader = app.otherElements["favorites"]

    app.day2TrackCell.tapTrailingAction(withIdentifier: "Favorite")

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
      XCTAssertEqual(app.tracksTable.cells.count, 15)
    }

    runActivity(named: "Select day 2") {
      filtersButton.tap()
      filterButtons.element(boundBy: 1).tap() // day 2
      XCTAssertTrue(day2Header.exists)
      XCTAssertTrue(favoritesHeader.exists)
      XCTAssertEqual(app.tracksTable.cells.count, 24)
    }

    runActivity(named: "Select all") {
      filtersButton.tap()
      filterButtons.element(boundBy: 0).tap() // all
      XCTAssertTrue(allHeader.exists)
      XCTAssertTrue(favoritesHeader.exists)
      XCTAssertEqual(app.tracksTable.cells.count, 39)
    }
  }

  func testPopToRoot() {
    let app = XCUIApplication()
    app.launch()
    app.searchButton.tap()

    runActivity(named: "Pop events") {
      app.day1TrackCell.tap()
      wait { app.trackTable.exists }

      app.searchButton.tap()
      XCTAssertTrue(app.tracksTable.exists)
      XCTAssertFalse(app.trackTable.exists)
    }

    runActivity(named: "Pop event") {
      app.day1TrackCell.tap()
      app.eventCell.tap()
      wait { app.eventTable.exists }

      app.searchButton.tap()
      XCTAssertTrue(app.tracksTable.exists)
      XCTAssertFalse(app.eventTable.exists)
    }
  }

  func testCollapseExpand() {
    let app = XCUIApplication()

    runActivity(named: "Handle welcome") {
      let welcomeView = app.otherElements["welcome"]

      app.launch()
      app.searchButton.tap()
      wait { app.tracksTable.exists }
      wait { !welcomeView.exists }

      XCUIDevice.shared.orientation = .landscapeLeft
      wait { app.tracksTable.exists }
      wait { welcomeView.exists }

      XCUIDevice.shared.orientation = .portrait
      wait { app.tracksTable.exists }
      wait { !welcomeView.exists }
    }

    runActivity(named: "Handle others") {
      app.day1TrackCell.tap()
      wait { app.trackTable.exists }
      wait { !app.tracksTable.exists }

      XCUIDevice.shared.orientation = .landscapeRight
      wait { app.trackTable.exists }
      wait { app.tracksTable.exists }

      app.eventCell.tap()
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

extension XCUIApplication {
  var searchButton: XCUIElement {
    tabBars.buttons["search"]
  }

  var trackTable: XCUIElement {
    tables["events"]
  }

  var day1TrackCellIdentifier: String {
    "Collaborative Information and Content Management Applications"
  }

  var day1TrackCell: XCUIElement {
    tracksTable.cells[day1TrackCellIdentifier]
  }

  var day1TrackEventCell: XCUIElement {
    eventCell
  }
}

private extension XCUIApplication {
  var tracksTable: XCUIElement {
    tables["tracks"]
  }

  var day2TrackCell: XCUIElement {
    tracksTable.cells["Containers"]
  }

  var eventCell: XCUIElement {
    trackTable.cells["Living on the edge with CryptPad"]
  }
}
