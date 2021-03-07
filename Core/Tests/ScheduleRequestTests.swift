@testable
import Core
import XCTest

final class ScheduleRequestTests: XCTestCase {
  func testDecode() throws {
    let year = 2020
    let data = try XCTUnwrap(BundleDataLoader().data(forResource: "\(year)", withExtension: "xml"))

    let requestURL = URL(string: "https://fosdem.org/2020/schedule/xml")
    let request = ScheduleRequest(year: year)
    XCTAssertEqual(request.url, requestURL)
    XCTAssertNoThrow(try request.decode(data))
  }
}
