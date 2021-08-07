@testable
import Fosdem
import XCTest

final class InfoControllerTests: XCTestCase {
  private struct Dependencies: InfoController.Dependencies {
    let infoService: InfoServiceProtocol
  }

  func testLoadInfo() {
    let font = UIFont.fos_preferredFont(forTextStyle: .body)
    let attributes: [NSAttributedString.Key: Any] = [.font: font]
    let attributedText = NSAttributedString(string: "something", attributes: attributes)

    let infoService = InfoServiceProtocolMock()
    infoService.loadAttributedTextHandler = { _, completion in
      completion(.success(attributedText))
    }

    let dependencies = Dependencies(infoService: infoService)

    let infoController = InfoController(info: .bus, dependencies: dependencies)
    let infoViewController = infoController.makeInfoViewController()
    infoController.loadInfo()

    wait { infoViewController.attributedText == attributedText }
    XCTAssertEqual(infoService.loadAttributedTextArgValues, [.bus])
  }

  func testLoadInfoError() {
    let error = NSError(domain: "test", code: 1)

    let infoService = InfoServiceProtocolMock()
    infoService.loadAttributedTextHandler = { _, completion in
      completion(.failure(error))
    }

    let dependencies = Dependencies(infoService: infoService)

    let infoController = InfoController(info: .bus, dependencies: dependencies)
    let infoViewController = infoController.makeInfoViewController()

    let expectation = self.expectation(description: #function)
    infoController.didError = { receivedViewController, receivedError in
      XCTAssertEqual(receivedViewController, infoViewController)
      XCTAssertEqual(receivedError as NSError, error)
      expectation.fulfill()
    }

    infoController.loadInfo()

    waitForExpectations(timeout: 1)
    XCTAssertEqual(infoService.loadAttributedTextArgValues, [.bus])
  }
}
