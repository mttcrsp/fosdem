@testable
import Fosdem
import XCTest

final class ScheduleRequestTests: XCTestCase {
  func testDecode() throws {
    let year = 2020
    let data = try XCTUnwrap(BundleDataLoader().data(forResource: "\(year)", withExtension: "xml"))

    let requestURL = URL(string: "https://fosdem.org/2020/schedule/xml")
    let request = ScheduleRequest(year: year)
    XCTAssertEqual(request.url, requestURL)
    XCTAssertNoThrow(try request.decode(data, response: nil))
  }

  func testNotFound() throws {
    let request = ScheduleRequest(year: 2020)
    let response = HTTPURLResponse(url: request.url, statusCode: 404, httpVersion: nil, headerFields: nil)
    XCTAssertThrowsError(try request.decode(Data(), response: response)) { error in
      XCTAssertEqual(error as? ScheduleRequest.Error, .notFound)
    }
  }
}
