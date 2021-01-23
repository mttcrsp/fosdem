import XCTest

final class AppliationControllerTests: XCTestCase {
  func test2021Notice() {
    let app = XCUIApplication()

    runActivity(named: "Visit fosdem.org") {
      app.launchEnvironment = ["ENABLE_NOTICES": "1", "RESET_DEFAULTS": "1"]
      app.launch()

      let visitButton = app.alerts.buttons.element(boundBy: 0)
      visitButton.tap()

      let aboutLink = app.links["About"]
      wait { aboutLink.exists }

      let doneButton = app.buttons["Done"]
      doneButton.tap()
      XCTAssert(app.searchButton.exists)
      XCTAssertEqual(app.alerts.count, 0)

      app.terminate()
      app.launchEnvironment = ["ENABLE_NOTICES": "1"]
      app.launch()
      XCTAssertEqual(app.alerts.count, 0)
    }

    runActivity(named: "Cancel") {
      app.terminate()
      app.launchEnvironment = ["ENABLE_NOTICES": "1", "RESET_DEFAULTS": "1"]
      app.launch()

      let cancelButton = app.alerts.buttons.element(boundBy: 1)
      cancelButton.tap()
      XCTAssertEqual(app.alerts.count, 0)

      app.terminate()
      app.launchEnvironment = ["ENABLE_NOTICES": "1"]
      app.launch()
      XCTAssertEqual(app.alerts.count, 0)
    }
  }
}
