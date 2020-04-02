@testable
import Fosdem
import XCTest

final class ScheduleXMLParserTests: XCTestCase {
    func testDecoding() {
        for year in 2007 ... 2020 {
            guard let data = BundleDataLoader().data(forResource: "\(year)", withExtension: "xml") else {
                return XCTFail("Unable to load schedule data for '\(year)'")
            }

            let parser = ScheduleXMLParser(data: data)

            XCTAssert(parser.parse())
            XCTAssertNil(parser.parseError)
            XCTAssertNil(parser.validationError)

            XCTAssertNotNil(parser.schedule)
            XCTAssertGreaterThan(parser.schedule?.days.last?.events.count ?? 0, 0)
            XCTAssertGreaterThan(parser.schedule?.days.first?.events.count ?? 0, 0)
        }
    }
}
