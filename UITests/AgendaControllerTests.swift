import XCTest

final class AgendaControllerTests: XCTestCase {
  func testAppearance() {
    let app = XCUIApplication()
    app.launchEnvironment = [
      "LIVE_INTERVAL": "1",
      "LIVE_DATES": "2020-02-01T09:32:00Z,2020-02-01T09:37:00Z",
      "FAVORITE_EVENTS": "10682,10683",
    ]
    app.launch()
    app.agendaButton.tap()

    runActivity(named: "Captions") {
      XCTAssert(app.staticTexts["10:30 - AW1.125 - Ada"].exists)
      XCTAssert(app.staticTexts["10:35 - AW1.125 - Ada"].exists)
      XCTAssert(app.staticTexts["Welcome to the Ada DevRoom"].exists)
      XCTAssert(app.staticTexts["An Introduction to Ada for Beginning and Experienced Programmers"].exists)
    }

    runActivity(named: "Live status") {
      let liveImage1 = app.cells.element(boundBy: 0).images["live"]
      let liveImage2 = app.cells.element(boundBy: 1).images["live"]
      wait { liveImage1.exists && !liveImage2.exists }
      wait { !liveImage1.exists && liveImage2.exists }
    }
  }

  func testSoon() throws {
    let app = XCUIApplication()
    let soonTable = app.tables["events"]
    let soonCell = soonTable.cells.firstMatch
    let soonButton = app.buttons["soon"]
    let doneButton = app.buttons["dismiss"]

    runActivity(named: "Content unavailable") {
      app.launchEnvironment = ["SOON_DATE": "2049-12-31T23:00:00Z"]
      app.launch()
      app.agendaButton.tap()
      soonButton.tap()
      wait { app.emptyStaticText.exists }
    }

    runActivity(named: "Content available") {
      app.terminate()
      app.launchEnvironment = ["RESET_DEFAULTS": "1", "SOON_DATE": "2020-02-01T09:45:00Z"]
      app.launch()
      app.agendaButton.tap()
      soonButton.tap()
      wait { app.staticTexts["BlackParrot"].exists }
      wait { app.staticTexts["10:50 - K.3.401"].exists }
      XCTAssertEqual(app.tables.firstMatch.cells.count, 24)
    }

    runActivity(named: "Open event") {
      soonCell.tap()
      wait { app.eventTable.exists }
    }

    runActivity(named: "Favorite") {
      app.backButton.tap()
      soonCell.tapFirstTrailingAction()
      doneButton.tap()
      XCTAssertEqual(app.agendaTable.cells.count, 1)
    }

    runActivity(named: "Unfavorite") {
      soonButton.tap()
      soonCell.tapFirstTrailingAction()
      doneButton.tap()
      XCTAssert(app.emptyStaticText.exists)
    }
  }

  func testFavorites() {
    let app = XCUIApplication()
    app.launchEnvironment = ["FAVORITE_EVENTS": "10682,10683"]
    app.launch()
    app.agendaButton.tap()

    runActivity(named: "Unfavorite from top") {
      app.agendaCell1.tapFirstTrailingAction()
      app.agendaCell1.tapFirstTrailingAction()
      XCTAssert(app.emptyStaticText.exists)
    }

    runActivity(named: "Unfavorite from bottom") {
      app.terminate()
      app.launch()
      app.agendaCell2.tapFirstTrailingAction()
      app.agendaCell1.tapFirstTrailingAction()
      XCTAssert(app.emptyStaticText.exists)
    }

    runActivity(named: "Unfavorite from event") {
      app.terminate()
      app.launch()
      app.agendaCell1.tap()
      app.unfavoriteEventButton.tap()
      app.backButton.tap()
      app.agendaCell1.tap()
      app.unfavoriteEventButton.tap()
      XCTAssert(app.emptyStaticText.exists)
    }

    runActivity(named: "Favorite") {
      app.searchButton.tap()
      app.day1TrackStaticText.tap()
      app.day1TrackStaticText.tapFirstTrailingAction()
      app.backButton.tap()
      app.agendaButton.tap()
      XCTAssertEqual(app.agendaTable.cells.count, 1)
    }
  }

  func testCollapseExpand() {
    XCUIDevice.shared.orientation = .landscapeLeft
    defer { XCUIDevice.shared.orientation = .portrait }

    let app = XCUIApplication()
    app.launchEnvironment = ["FAVORITE_EVENTS": "10682"]
    app.launch()

    runActivity(named: "Handle expanded launch") {
      app.agendaButton.tap()
      wait { app.eventTable.exists }
      wait { app.agendaTable.exists }
    }

    runActivity(named: "Handle collapse") {
      XCUIDevice.shared.orientation = .portrait
      wait { app.eventTable.exists }
      wait { !app.agendaTable.exists }
    }

    runActivity(named: "Handle expand") {
      XCUIDevice.shared.orientation = .landscapeRight
      wait { app.eventTable.exists }
      wait { app.agendaTable.exists }
    }

    runActivity(named: "Handle empty expanded") {
      app.agendaCell1.tapFirstTrailingAction()
      wait { !app.eventTable.exists }
      wait { app.emptyStaticText.exists }
    }
  }

  func testPopToRoot() {
    let app = XCUIApplication()
    app.launchEnvironment = ["FAVORITE_EVENTS": "10682"]
    app.launch()
    app.agendaButton.tap()

    app.agendaTable.cells.firstMatch.tap()
    wait { app.eventTable.exists }
    wait { !app.agendaTable.exists }

    app.agendaButton.tap()
    wait { !app.eventTable.exists }
    wait { app.agendaTable.exists }
  }
}

extension XCUIApplication {
  var agendaButton: XCUIElement {
    tabBars.buttons["agenda"]
  }
}

private extension XCUIApplication {
  var agendaTable: XCUIElement {
    tables["events"]
  }

  var agendaCell1: XCUIElement {
    agendaTable.cells.element(boundBy: 0)
  }

  var agendaCell2: XCUIElement {
    agendaTable.cells.element(boundBy: 1)
  }

  var emptyStaticText: XCUIElement {
    staticTexts["background_title"]
  }
}
