import XCTest

final class ScreenshotTests: XCTestCase {
  func testScreenshots() throws {
    let device = try XCTUnwrap(ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"])

    let app = XCUIApplication()
    app.launchEnvironment = [
      "SET_FAVORITE_EVENTS": "10746,9662,9743,9457,10213,9189",
      "SET_FAVORITE_TRACKS": "LLVM,Containers",
    ]
    app.launch()

    let takeScreenshot: (String) -> Void = { name in
      let screenshot = app.screenshot()
      let attachment = XCTAttachment(screenshot: screenshot, quality: .original)
      attachment.lifetime = .keepAlways
      attachment.name = "\(device)_\(name)"
      self.add(attachment)
    }

    runActivity(named: "Search") {
      app.searchButton.tap()
      takeScreenshot("1_search")
    }

    runActivity(named: "Agenda") {
      app.agendaButton.tap()
      Thread.sleep(forTimeInterval: 1) // hide scroll indicator
      takeScreenshot("2_agenda")
    }

    runActivity(named: "Map") {
      app.mapButton.tap()
      app.niceBuildingView.tap()
      wait { app.blueprintsContainer.exists }

      if device.lowercased().contains("ipad") {
        let vector1 = CGVector(dx: 0.5, dy: 0.5)
        let vector2 = CGVector(dx: 0.57, dy: 0.55)
        let coordinate1 = app.coordinate(withNormalizedOffset: vector1)
        let coordinate2 = app.coordinate(withNormalizedOffset: vector2)
        coordinate1.press(forDuration: 0, thenDragTo: coordinate2)
      }

      takeScreenshot("3_map")
    }

    runActivity(named: "More") {
      app.moreButton.tap()
      Thread.sleep(forTimeInterval: 1) // hide scroll indicator
      takeScreenshot("4_more")
    }
  }
}
