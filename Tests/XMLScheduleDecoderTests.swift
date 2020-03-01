@testable
import Fosdem
import XCTest

final class XMLScheduleDecoderTests: XCTestCase {
    func testDecoding() {
        for year in 2007 ... 2020 {
            guard let url = bundle.url(forResource: "\(year)", withExtension: "xml") else {
                return XCTFail("Unable to locate schedule for year '\(year)'")
            }

            guard let data = try? Data(contentsOf: url) else {
                return XCTFail("Unable to load schedule data for '\(year)'")
            }

            let decoder = XMLScheduleDecoder(data: data)

            XCTAssert(decoder.parse())
            XCTAssertNil(decoder.parseError)
            XCTAssertNil(decoder.validationError)

            XCTAssertNotNil(decoder.schedule)
            XCTAssertGreaterThan(decoder.schedule?.days.last?.events.count ?? 0, 0)
            XCTAssertGreaterThan(decoder.schedule?.days.first?.events.count ?? 0, 0)
        }
    }
}
