import XCTest

final class EventControllerTests: XCTestCase {
  func testFavoriteStatus() {}
  func testFavoriteEvent() {}
  func testUnfavoriteEvent() {}

  func testVideo() {} //  + playback position
  func testAttachment() {}
}

extension XCUIApplication {
  var eventTable: XCUIElement {
    tables["event"]
  }

  var favoriteEventButton: XCUIElement {
    buttons["favorite"]
  }

  var unfavoriteEventButton: XCUIElement {
    buttons["unfavorite"]
  }
}
