@testable
import Fosdem
import XCTest

final class InfoServiceTests: XCTestCase {
    func testLoadAttributedText() {
        let url = URL(fileURLWithPath: "/url/local/fosdem")
        let htmlString = #"<p>standard <strong>bold</strong> <strong><a href="https://www.fosdem.org">link</a></strong></p>"#
        let htmlData = Data(htmlString.utf8)

        let provider = InfoServiceDataProviderMock(data: htmlData)
        let bundle = InfoServiceBundleMock(url: url)

        let expectation = self.expectation(description: #function)

        let service = InfoService(queue: .main, bundle: bundle, provider: provider)
        service.loadAttributedText(for: .bus) { attributedText in
            guard let attributedText = attributedText else {
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

            XCTAssertEqual(provider.url, url)
            XCTAssertEqual(bundle.ext, "html")
            XCTAssertEqual(bundle.name, "bus-tram")
            XCTAssertEqual(attributesData.count, 5)

            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.5)
    }
}
