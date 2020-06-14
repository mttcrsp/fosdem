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
    let settingsApp = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
    defer { settingsApp.terminate() }

    let app = XCUIApplication()
    let locationButton = app.buttons["location"]
    let locationAvailableButton = app.buttons["location_available"]
    let locationUnavailableButton = app.buttons["location_unavailable"]

    let dismissButton = app.alerts.buttons.element(boundBy: 0)
    let confirmButton = app.alerts.buttons.element(boundBy: 1)

    runActivity(named: "Allow location services") {
      addUIInterruptionMonitor(withDescription: "Location Services") { alert in
        alert.buttons["Allow While Using App"].tap()
        return true
      }

      settingsApp.launch()
      settingsApp.cells["Privacy"].tap()
      settingsApp.cells["Location Services"].tap()

      let fosdemPredicate = NSPredicate(format: "label CONTAINS %@", "FOSDEM")
      let fosdemCell = settingsApp.cells.element(matching: fosdemPredicate)
      fosdemCell.tap()

      settingsApp.cells["Ask Next Time"].tap()

      app.launch()
      app.mapButton.tap()

      // WORKAROUND: When an alert is presented the application process looses
      // its focus. This means that assertions will fail to locate elements from
      // the application UI. In order to workaround this issue, force the app
      // back into focus by interacting with some element.
      locationButton.tap()
      app.mapButton.tap()
      XCTAssert(locationAvailableButton.exists)
    }

    runActivity(named: "Deny Location services") {
      locationAvailableButton.tap()
      dismissButton.tap()
      locationAvailableButton.tap()
      confirmButton.tap()

      settingsApp.cells["Never"].tap()
      app.activate()
      XCTAssert(locationUnavailableButton.exists)
    }

    runActivity(named: "Re-allow location services") {
      locationUnavailableButton.tap()
      dismissButton.tap()
      locationUnavailableButton.tap()
      confirmButton.tap()

      settingsApp.cells["While Using the App"].tap()
      app.activate()
      XCTAssert(locationAvailableButton.exists)
    }
  }

  func testEmbeddedBlueprints() {
    let app = XCUIApplication()
    app.launch()
    app.mapButton.tap()

    let blueprintsNavBar = app.blueprintsContainer.navigationBars.firstMatch

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

    app.buttons["fullscreen_dismiss"].tap()
    XCTAssertFalse(app.pageIndicator.exists)

    app.buttons["fullscreen"].tap()
    XCTAssertTrue(app.pageIndicator.exists)

    app.swipeDown()
    XCTAssertFalse(app.pageIndicator.exists)
  }
}

private extension XCUIApplication {
  var mapButton: XCUIElement {
    tabBars.buttons["map"]
  }

  var map: XCUIElement {
    maps.firstMatch
  }

  var buildingView: XCUIElement {
    map.otherElements["K"]
  }

  var noBlueprintBuildingView: XCUIElement {
    map.otherElements["F1"]
  }

  var blueprintsContainer: XCUIElement {
    scrollViews.firstMatch
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
    map.otherElements[identifier]
  }
}
