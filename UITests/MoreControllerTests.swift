import XCTest

final class MoreControllerTests: XCTestCase {
  func testItems() {
    let app = XCUIApplication()
    app.launch()
    app.moreButton.tap()

    runActivity(named: "Info items") {
      for identifier in ["history", "devrooms", "legal"] {
        app.cells[identifier].tap()
        wait { app.textViews[identifier].exists }
        app.backButton.tap()
      }
    }

    let safari = XCUIApplication.safari

    runActivity(named: "Contribute") {
      app.cells["code"].tap()
      XCTAssert(safari.wait(for: .runningForeground, timeout: 10))

      safari.urlButton.tap()
      XCTAssertEqual(safari.urlTextField.value as? String, "https://github.com/mttcrsp/fosdem")
    }

    runActivity(named: "Acknowledgements") {
      app.activate()
      app.cells["acknowledgements"].tap()
      wait { app.cells.count > 0 }

      app.staticTexts["XcodeGen"].tap()
      XCTAssert(safari.wait(for: .runningForeground, timeout: 10))

      safari.urlButton.tap()
      XCTAssertEqual(safari.urlTextField.value as? String, "https://github.com/yonaskolb/XcodeGen")
    }
  }

  func testTransportation() {
    let app = XCUIApplication()
    app.launch()
    app.moreButton.tap()

    runActivity(named: "Info items") {
      app.cells["transportation"].tap()

      for identifier in ["bus", "shuttle", "train", "car", "plane", "taxi"] {
        app.cells[identifier].tap()
        wait { app.textViews[identifier].exists
        }
        app.backButton.tap()
      }
    }

    runActivity(named: "Apple Maps") {
      app.cells["appleMaps"].tap()

      let maps = XCUIApplication(bundleIdentifier: "com.apple.Maps")
      XCTAssert(maps.wait(for: .runningForeground, timeout: 10))

      addUIInterruptionMonitor(withDescription: "Location services") { alert in
        alert.buttons["Don’t Allow"].tap()
        return true
      }

      let mapsOnboardingButton = maps.buttons["Continue"]
      if mapsOnboardingButton.exists {
        mapsOnboardingButton.tap()
      }

      maps.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0)).tap()
    }

    runActivity(named: "Google Maps") {
      app.activate()
      app.cells["googleMaps"].tap()

      let safari = XCUIApplication.safari
      XCTAssert(safari.wait(for: .runningForeground, timeout: 10))

      safari.urlButton.tap()
      XCTAssertEqual((safari.urlTextField.value as? String)?.contains("google.com/maps"), true)
    }
  }

  func testCollapseExpand() {
    XCUIDevice.shared.orientation = .landscapeRight
    defer { XCUIDevice.shared.orientation = .portrait }

    let app = XCUIApplication()
    let isMasterVisible: () -> Bool = { app.cells["history"].exists }
    let isDetailVisible: () -> Bool = { app.textViews["history"].exists }

    app.launch()
    app.moreButton.tap()
    wait { isMasterVisible() && isDetailVisible() }

    XCUIDevice.shared.orientation = .portrait
    app.terminate()
    app.launch()
    wait { isMasterVisible() && !isDetailVisible() }

    XCUIDevice.shared.orientation = .landscapeLeft
    wait { isMasterVisible() && isDetailVisible() }
  }

  func testPopToRoot() {
    let app = XCUIApplication()
    app.launch()
    app.moreButton.tap()
    app.cells["years"].tap()
    app.cells["2019"].tap()
    app.moreButton.tap()
    XCTAssert(app.cells["years"].exists)
  }
}

extension XCUIApplication {
  var moreButton: XCUIElement {
    buttons["more"]
  }
}

private extension XCUIApplication {
  static var safari: XCUIApplication {
    XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
  }

  var urlTextField: XCUIElement {
    textFields.firstMatch
  }

  var urlButton: XCUIElement {
    buttons["URL"]
  }
}
