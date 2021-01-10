import XCTest

final class VideoControllerTests: XCTestCase {
  func testVideos() {
    guard let data = BundleDataLoader().data(forResource: "test", withExtension: "mp4") else {
      return XCTFail("Unable to load video")
    }

    let app = XCUIApplication()
    app.launchEnvironment = ["RESET_DEFAULTS": "1", "VIDEO": data.base64EncodedString()]
    app.launch()

    // WORKAROUND: UISegmented control does not support custom accessibility
    // identifiers for its segments
    let watchingButton = app.segmentedControls.buttons.element(boundBy: 0)
    let watchedButton = app.segmentedControls.buttons.element(boundBy: 1)

    runActivity(named: "Watching updates") {
      app.searchButton.tap()
      app.day1TrackCell.tap()
      app.day1TrackEventCell.tap()
      app.buttons["play"].tap()
      app.buttons["Done"].tap()
      app.moreButton.tap()
      app.cells["video"].tap()
      XCTAssert(app.day1TrackEventCell.exists)
    }

    runActivity(named: "Watched updates") {
      watchedButton.tap()
      XCTAssert(app.staticTexts["background_title"].exists)
      XCTAssert(app.staticTexts["background_message"].exists)

      watchingButton.tap()
      app.day1TrackEventCell.tap()
      app.buttons["resume"].tap()
      wait(timeout: 15) { app.backButton.exists }

      app.backButton.tap()
      XCTAssert(app.staticTexts["background_title"].exists)
      XCTAssert(app.staticTexts["background_message"].exists)

      watchedButton.tap()
      XCTAssert(app.day1TrackEventCell.exists)
    }
  }
}
