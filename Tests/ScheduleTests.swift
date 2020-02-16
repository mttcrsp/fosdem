@testable
import Fosdem
import XCTest
import XMLCoder

final class ScheduleTests: XCTestCase {
    func testDecoding() {
        for year in 2007 ... 2020 {
            guard let url = bundle.url(forResource: "\(year)", withExtension: "xml") else {
                return XCTFail("Unable to locate schedule for year '\(year)'")
            }

            guard let data = try? Data(contentsOf: url) else {
                return XCTFail("Unable to load schedule data for '\(year)'")
            }

            let decoder = XMLDecoder.default
            let schedule = try? decoder.decode(Schedule.self, from: data)
            let events = schedule?.events ?? []
            XCTAssert(events.contains { event in event.links.count > 0 })
            XCTAssert(events.contains { event in event.people.count > 0 })

            if year == 2020 {
                XCTAssert(events.contains { event in event.attachments.count > 0 })
            }
        }
    }
}

private extension Schedule {
    var events: [Event] {
        days.flatMap { day in day.events }
    }
}
