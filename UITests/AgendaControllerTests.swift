import XCTest

final class AgendaControllerTests: XCTestCase {
  func testAppearance() {
    let components1 = DateComponents(year: 2020, month: 2, day: 1, hour: 10, minute: 32)
    let components2 = DateComponents(year: 2020, month: 2, day: 1, hour: 10, minute: 37)
    guard let interval1 = interval(for: components1), let interval2 = interval(for: components2) else {
      return XCTFail("Failed to instantiate mock dates")
    }

    let app = XCUIApplication()
    app.launchEnvironment = [
      "LIVE_INTERVAL": "1",
      "LIVE_DATES": "\(interval1),\(interval2)",
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
    let components1 = DateComponents(year: 2050, month: 2, day: 1, hour: 10, minute: 30)
    let components2 = DateComponents(year: 2020, month: 2, day: 1, hour: 10, minute: 45)
    guard let interval1 = interval(for: components1), let interval2 = interval(for: components2) else {
      return XCTFail("Failed to instantiate mock dates")
    }

    let app = XCUIApplication()
    let soonTable = app.tables["events"]
    let soonCell = soonTable.cells.firstMatch
    let soonButton = app.buttons["soon"]
    let doneButton = app.buttons["dismiss"]

    runActivity(named: "Content unavailable") {
      app.launchEnvironment = ["SOON_DATE": "\(interval1)"]
      app.launch()
      app.agendaButton.tap()
      soonButton.tap()
      wait { app.emptyStaticText.exists }
    }

    runActivity(named: "Content available") {
      app.terminate()
      app.launchEnvironment = ["RESET_DEFAULTS": "1", "SOON_DATE": "\(interval2)"]
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
      soonCell.tapTrailingAction(withIdentifier: "Add to Agenda")
      doneButton.tap()
      XCTAssertEqual(app.agendaTable.cells.count, 1)
    }

    runActivity(named: "Unfavorite") {
      soonButton.tap()
      soonCell.tapTrailingAction(withIdentifier: "Remove from Agenda")
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
      app.agendaCell1.tapTrailingAction(withIdentifier: "Remove from Agenda")
      app.agendaCell1.tapTrailingAction(withIdentifier: "Remove from Agenda")
      XCTAssert(app.emptyStaticText.exists)
    }

    runActivity(named: "Unfavorite from bottom") {
      app.terminate()
      app.launch()
      app.agendaCell2.tapTrailingAction(withIdentifier: "Remove from Agenda")
      app.agendaCell1.tapTrailingAction(withIdentifier: "Remove from Agenda")
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
      app.day1TrackCell.tap()
      app.day1TrackEventCell.tapTrailingAction(withIdentifier: "Add to Agenda")
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
      app.agendaCell1.tapTrailingAction(withIdentifier: "Remove from Agenda")
      wait { !app.eventTable.exists }
      wait { app.emptyStaticText.exists }
    }
  }

  func testPopToRoot() {
    let app = XCUIApplication()
    app.launchEnvironment = ["FAVORITE_EVENTS": "10682"]
    app.launch()
    app.agendaButton.tap()
    wait { app.agendaTable.exists }

    app.agendaTable.cells.firstMatch.tap()
    wait { app.eventTable.exists }
    wait { !app.agendaTable.exists }

    app.agendaButton.tap()
    wait { !app.eventTable.exists }
    wait { app.agendaTable.exists }
  }

  private func interval(for components: DateComponents) -> Double? {
    Calendar.autoupdatingCurrent.date(from: components)?.timeIntervalSince1970
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
