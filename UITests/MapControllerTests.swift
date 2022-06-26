import XCTest

final class MapControllerTests: XCTestCase {
  func testRegion() {
    let app = XCUIApplication()
    app.launch()
    app.mapButton.tap()

    runActivity(named: "Initial region") {
      wait { app.areAllBuildingsVisibile }
    }

    runActivity(named: "Away region") {
      app.map.swipeDown()
      app.map.swipeRight()
      wait { !app.areAllBuildingsVisibile }
    }

    runActivity(named: "Reset") {
      app.buttons["reset"].tap()
      wait { app.areAllBuildingsVisibile }
    }
  }

  func testLocation() {
    let settings = XCUIApplication.settings
    defer { settings.terminate() }

    let app = XCUIApplication()
    let locationButton = app.buttons["location"]
    let locationAvailableButton = app.buttons["location_available"]
    let locationUnavailableButton = app.buttons["location_unavailable"]

    let dismissButton = app.alerts.buttons.element(boundBy: 0)
    let confirmButton = app.alerts.buttons.element(boundBy: 1)

    runActivity(named: "Force location services section to appear") {
      app.launch()
      app.mapButton.tap()
    }

    runActivity(named: "Allow location services") {
      addUIInterruptionMonitor(withDescription: "Location Services") { alert in
        // Attempts to match "Allow While Using App" will fail in Xcode 12.4
        alert.buttons.element(boundBy: 1).tap()
        return true
      }

      app.activate()
      app.mapButton.tap()
      locationButton.tap()

      // WORKAROUND: When an alert is presented the application process looses
      // its focus. This means that assertions will fail to locate elements from
      // the application UI. In order to workaround this issue, force the app
      // back into focus by interacting with some element. On iOS 14, you also
      // need to wait for the alert to be dismissed before attempting this tap.
      wait { app.mapButton.isHittable }
      app.mapButton.tap()

      XCTAssert(locationAvailableButton.exists)
    }

    runActivity(named: "Deny Location services") {
      locationAvailableButton.tap()
      dismissButton.tap()
      locationAvailableButton.tap()
      confirmButton.tap()

      settings.activate()
      settings.staticTexts["LOCATION_SERVICES_AUTH_NEVER"].tap()
      app.activate()
      wait { locationUnavailableButton.exists }
    }

    runActivity(named: "Re-allow location services") {
      locationUnavailableButton.tap()
      dismissButton.tap()
      locationUnavailableButton.tap()
      confirmButton.tap()

      settings.activate()
      settings.staticTexts["LOCATION_SERVICES_AUTH_WHEN_IN_USE"].tap()
      app.activate()
      XCTAssert(locationAvailableButton.exists)
    }
  }

  func testEmbeddedBlueprints() {
    let app = XCUIApplication()
    app.launch()
    app.mapButton.tap()

    let blueprintsNavBar = app.navigationBars.firstMatch

    app.buildingView.tap()
    var titles: Set<String> = []
    for _ in 1 ... 6 {
      titles.insert(blueprintsNavBar.identifier)
      app.blueprintsContainer.swipeLeft()
    }
    XCTAssertEqual(titles.count, 5)
    XCTAssertFalse(app.pageIndicator.exists)
    app.blueprintsContainer.swipeDown()

    app.buildingView.tap()
    app.buttons["dismiss"].tap()
    wait { !blueprintsNavBar.exists }

    XCUIDevice.shared.orientation = .landscapeLeft
    app.buildingView.tap()
    blueprintsNavBar.swipeLeft()
    wait { !blueprintsNavBar.exists }

    XCUIDevice.shared.orientation = .portrait
    app.buttons["reset"].tap()
    app.noBlueprintBuildingView.tap()
    wait { app.staticTexts["empty_blueprints"].exists }
  }

  func testFullscreenBlueprints() {
    let app = XCUIApplication()
    app.launch()
    app.mapButton.tap()
    app.buildingView.tap()
    app.blueprintsContainer.tap()

    for i in 1 ... 5 {
      XCTAssertEqual(app.pageIndicator.value as? String, "page \(i) of 5")
      app.swipeLeft()
    }

    app.otherElements["fullscreen_blueprints"].doubleTap()
    app.blueprintsFullscreenDismissButton.tap()
    XCTAssertFalse(app.pageIndicator.exists)

    app.buttons["fullscreen"].tap()
    XCTAssertTrue(app.pageIndicator.exists)

    app.swipeDown()
    XCTAssertFalse(app.pageIndicator.exists)
  }
}

extension XCUIApplication {
  var mapButton: XCUIElement {
    tabBars.buttons["map"]
  }

  var buildingView: XCUIElement {
    buildingView(forIdentifier: "K")
  }

  var niceBuildingView: XCUIElement {
    buildingView(forIdentifier: "U")
  }

  var blueprintsContainer: XCUIElement {
    otherElements["embedded_blueprints"]
  }

  var blueprintsFullscreenDismissButton: XCUIElement {
    buttons["fullscreen_dismiss"]
  }
}

private extension XCUIApplication {
  var map: XCUIElement {
    maps.firstMatch
  }

  var noBlueprintBuildingView: XCUIElement {
    buildingView(forIdentifier: "F1")
  }

  var pageIndicator: XCUIElement {
    pageIndicators.firstMatch
  }

  var areAllBuildingsVisibile: Bool {
    for identifier in ["AW", "F1", "J", "H", "U", "K"] {
      if !buildingView(forIdentifier: identifier).exists {
        return false
      }
    }
    return true
  }

  func buildingView(forIdentifier identifier: String) -> XCUIElement {
    otherElements["building_\(identifier)"]
  }
}
