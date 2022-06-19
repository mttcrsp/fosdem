@testable
import Fosdem
import XCTest

final class InfoServiceTests: XCTestCase {
  func testLoadAttributedText() {
    let htmlString = #"<p>standard <strong>bold</strong> <strong><a href="https://www.fosdem.org">link</a></strong></p>"#
    let htmlData = Data(htmlString.utf8)

    let bundle = BundleServiceProtocolMock()
    bundle.dataHandler = { _, _ in htmlData }

    let expectation = self.expectation(description: #function)

    let service = InfoService(queue: .main, bundleService: bundle)
    service.loadAttributedText(for: .bus) { result in
      guard case let .success(attributedText) = result else {
        return XCTFail("Unexpectedly returned nil while loading attributed text")
      }

      let string = attributedText.string
      let lowerbound = string.startIndex
      let upperbound = string.endIndex
      let range = NSRange(lowerbound ..< upperbound, in: string)

      var attributesData: [([NSAttributedString.Key: Any], NSRange)] = []
      attributedText.enumerateAttributes(in: range) { attributes, range, _ in
        attributesData.append((attributes, range))
      }

      XCTAssertEqual(bundle.dataCallCount, 1)
      XCTAssertEqual(bundle.dataArgValues.first?.0, "bus-tram")
      XCTAssertEqual(bundle.dataArgValues.first?.1, "html")
      XCTAssertEqual(attributesData.count, 5)

      expectation.fulfill()
    }

    waitForExpectations(timeout: 1)
  }
}
