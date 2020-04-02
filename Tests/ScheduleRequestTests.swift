@testable
import Fosdem
import XCTest

final class ScheduleRequestTests: XCTestCase {
    func testDecode() {
        let year = 2020

        guard let data = ScheduleDataLoader().scheduleData(forYear: year) else {
            return XCTFail("Unable to load schedule data for '\(year)'")
        }

        let requestURL = URL(string: "https://fosdem.org/2020/schedule/xml")
        let request = ScheduleRequest(year: year)
        XCTAssertEqual(request.url, requestURL)
        XCTAssertNoThrow(try request.decode(data))
    }
}
