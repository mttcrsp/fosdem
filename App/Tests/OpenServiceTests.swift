@testable
import Fosdem
import XCTest

final class OpenServiceTests: XCTestCase {
  func testOpen() {
    let application = OpenServiceApplicationMock()
    application.openHandler = { _, _, completion in
      completion?(true)
    }

    let url = URL(fileURLWithPath: "test")
    let expectation = expectation(description: #function)
    let openService = OpenService(application: application)
    openService.open(url) { succeeded in
      XCTAssertTrue(succeeded)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 1)
    XCTAssertEqual(application.openCallCount, 1)
    XCTAssertEqual(application.openArgValues.map(\.0).first, url)
    XCTAssertEqual(application.openArgValues.map(\.1).first?.isEmpty, true)
  }
}
