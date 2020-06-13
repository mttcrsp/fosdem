import XCTest

final class SearchControllerTests: XCTestCase {
  private var app: XCUIApplication {
    XCUIApplication()
  }

  override func setUp() {
    super.setUp()
    app.launch()
  }
  
  func testTracks() {} // + sections + titles + index
  func testFavoriteTrack() {}
  func testUnfavoriteTrack() {}

  func testEvents() {} // (+ captions)
  func testFavoriteEvent() {}
  func testUnfavoriteEvent() {}

  func testSearch() {}

  func testNavigateToTrack() {}
  func testNavigateToEvent() {}
  func testNavigateToResult() {}

  func testCollapseWelcome() {}
  func testPopToRoot() {
    runActivity(named: "Pop from events") {
      app.searchButton.tap()
      app.trackStaticText.tap()
      XCTAssertTrue(app.trackTable.exists)

      app.searchButton.tap()
      XCTAssertTrue(app.tracksTable.exists)
      XCTAssertFalse(app.trackTable.exists)
    }

    runActivity(named: "Pop from event") {
      app.trackStaticText.tap()
      app.eventStaticText.tap()
      XCTAssertTrue(app.eventTable.exists)

      app.searchButton.tap()
      XCTAssertTrue(app.tracksTable.exists)
      XCTAssertFalse(app.eventTable.exists)
    }
  }
}

extension XCTestCase {
  func runActivity(named: String, block: () -> Void) {
    XCTContext.runActivity(named: named) { _ in block() }
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

  private var trackName: String {
    "Ada"
  }

  private var eventTitle: String {
    "Welcome to the Ada DevRoom"
  }
}
