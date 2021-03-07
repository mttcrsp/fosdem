@testable
import Fosdem
import XCTest

final class AppStoreSearchRequestTests: XCTestCase {
  func testDecode() throws {
    let result1 = AppStoreSearchResult(bundleIdentifier: "nl.netsense.FOSDEM", version: "1.2.2")
    let result2 = AppStoreSearchResult(bundleIdentifier: "com.zerokspot.fosdem-to-go", version: "0.1")
    let response = AppStoreSearchResponse(results: [result1, result2])
    let requestURL = URL(string: "https://itunes.apple.com/us/search?term=fosdem&media=software&entity=software")!
    let request = AppStoreSearchRequest()
    XCTAssertEqual(request.url, requestURL)

    let data = try BundleDataLoader().data(forResource: "results", withExtension: "json")
    XCTAssertEqual(try request.decode(data), response)
  }
}
