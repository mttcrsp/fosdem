import XCTest

final class TraitsTests: XCTestCase {
  func testUserInterfaceStyle() {
    let app = XCUIApplication()
    app.launch()
    app.searchButton.tap()

    runActivity(named: "Show event") {
      app.day1TrackCell.tap()
      wait { app.trackTable.exists }
      app.day1TrackEventCell.tap()
    }

    runActivity(named: "Show fullscreen blueprints") {
      app.mapButton.tap()
      wait { app.buildingView.exists }
      app.buildingView.tap()
      app.blueprintsContainer.tap()
    }

    let settings = XCUIApplication.settings

    runActivity(named: "Enable dark mode") {
      settings.launch()
      settings.swipeUp()
      settings.cells["Developer"].tap()
      settings.switches["Dark Appearance"].tap()
    }

    runActivity(named: "Dismiss everything") {
      app.activate()
      app.blueprintsFullscreenDismissButton.tap()
      app.searchButton.tap()
      app.backButton.tap()
      app.backButton.tap()
    }

    runActivity(named: "Disable dark mode") {
      settings.activate()
      settings.switches["Dark Appearance"].tap()
    }
  }

  func testPreferredContentSizeCategory() {
    let app = XCUIApplication()
    app.launch()
    app.searchButton.tap()

    runActivity(named: "Present views") {
      app.day1TrackCell.tap()
      wait { app.trackTable.exists }
      app.day1TrackEventCell.tap()
      app.moreButton.tap()
      app.cells["history"].tap()
    }

    let settings = XCUIApplication.settings
    let sizeSlider = settings.sliders.firstMatch
    let maxSizeOffset = CGVector(dx: 1, dy: 0.5)
    let midSizeOffset = CGVector(dx: 0.5, dy: 0.5)
    let maxCoordinate = sizeSlider.coordinate(withNormalizedOffset: maxSizeOffset)
    let midCoordinate = sizeSlider.coordinate(withNormalizedOffset: midSizeOffset)

    runActivity(named: "Increase size") {
      settings.launch()
      settings.cells["Accessibility"].tap()
      settings.cells["Display & Text Size"].tap()
      settings.cells["Larger Text"].tap()
      maxCoordinate.tap()
    }

    runActivity(named: "Inspect views") {
      app.activate()
      app.searchButton.tap()
    }

    runActivity(named: "Decrease size") {
      settings.activate()
      midCoordinate.tap()
    }
  }
}
