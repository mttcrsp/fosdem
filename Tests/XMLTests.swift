@testable
import Fosdem
import XCTest

final class XMLTests: XCTestCase {
    func testDecoding() {
        let year = 2007

        guard let url = bundle.url(forResource: "\(year)", withExtension: "xml") else {
            return XCTFail("Unable to locate schedule for year '\(year)'")
        }

        guard let data = try? Data(contentsOf: url) else {
            return XCTFail("Unable to load schedule data for '\(year)'")
        }

        let decoder = XMLScheduleDecoder(data: data)
        XCTAssert(decoder.parse())
    }
}
