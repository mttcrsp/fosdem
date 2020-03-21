@testable
import Fosdem
import XCTest

final class YearsServiceTests: XCTestCase {
    func testYears() {
        var urls: [URL] = []
        urls.append(.init(fileURLWithPath: "/something/2009.sqlite"))
        urls.append(.init(fileURLWithPath: "/something/2010.sqlite"))
        urls.append(.init(fileURLWithPath: "/something/2011.sqlite"))

        let bundle = YearsServiceBundleMock(urls: urls)
        let service = YearsService(bundle: bundle)

        let expectation = self.expectation(description: #function)
        service.loadYears { years in
            XCTAssertEqual(years, ["2009", "2010", "2011"])
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.1)
    }
}

private struct YearsServiceBundleMock: YearsServiceBundle {
    let urls: [URL]

    func urls(forResourcesWithExtension _: String?, subdirectory _: String?) -> [URL]? {
        urls
    }
}
