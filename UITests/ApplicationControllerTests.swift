import SBTUITestTunnelClient
import XCTest

final class AppliationControllerTests: XCTestCase {
  func testOnboarding() {
    let app = XCUIApplication()
    app.launchEnvironment = ["ENABLE_ONBOARDING": "1", "RESET_DEFAULTS": "1"]
    app.launch()

    let continueButton = app.buttons["continue"]
    continueButton.tap()
    XCTAssert(app.searchButton.exists)

    app.terminate()
    app.launchEnvironment = ["ENABLE_ONBOARDING": "1"]
    app.launch()
    XCTAssert(app.searchButton.exists)
  }

  func testSomething() {
    app.launchTunnel(withOptions: [SBTUITunneledApplicationLaunchOptionResetFilesystem])
    app.performCustomCommandNamed("ENABLE_ONBOARDING", object: nil)

    XCTAssert(app.buttons["Search"].exists)
  }
}
