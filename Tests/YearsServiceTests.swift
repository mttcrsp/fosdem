@testable
import Fosdem
import XCTest

final class YearsServiceTests: XCTestCase {
  func testYears() {
    var urls: [URL] = []
    urls.append(.init(fileURLWithPath: "/something/2009.year"))
    urls.append(.init(fileURLWithPath: "/something/2010.year"))
    urls.append(.init(fileURLWithPath: "/something/2011.year"))

    let bundle = YearsServiceBundleMock(urls: urls)
    let service = YearsService(bundle: bundle)

    let expectation = self.expectation(description: #function)
    service.loadYears { years in
      XCTAssertEqual(years, ["2011", "2010", "2009"])
      expectation.fulfill()
    }
    waitForExpectations(timeout: 0.1)
  }

  func testURLForYear() {
    let url = URL(fileURLWithPath: "/something/2009.sqlite")
    let bundle = YearsServiceBundleMock(url: url)
    let service = YearsService(bundle: bundle)

    let expectation = self.expectation(description: #function)
    service.loadURL(forYear: "2009") { receivedURL in
      XCTAssertEqual(receivedURL, url)
      expectation.fulfill()
    }
    waitForExpectations(timeout: 0.1)
  }
}

private struct YearsServiceBundleMock: YearsServiceBundle {
  let url: URL?, urls: [URL]?

  init(url: URL? = nil, urls: [URL]? = nil) {
    self.url = url
    self.urls = urls
  }

  func url(forResource name: String?, withExtension ext: String?) -> URL? {
    url
  }

  func urls(forResourcesWithExtension ext: String?, subdirectory subpath: String?) -> [URL]? {
    urls
  }
}
