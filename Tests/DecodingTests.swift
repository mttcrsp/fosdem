@testable
import Fosdem
import XCTest
import XMLCoder

final class DecodingTests: XCTestCase {
    func testDecoding2007() {
        testDecoding(forYear: 2007)
    }

    func testDecoding2008() {
        testDecoding(forYear: 2008)
    }

    func testDecoding2009() {
        testDecoding(forYear: 2009)
    }

    func testDecoding2010() {
        testDecoding(forYear: 2010)
    }

    func testDecoding2011() {
        testDecoding(forYear: 2011)
    }

    func testDecoding2012() {
        testDecoding(forYear: 2012)
    }

    func testDecoding2013() {
        testDecoding(forYear: 2013)
    }

    func testDecoding2014() {
        testDecoding(forYear: 2014)
    }

    func testDecoding2015() {
        testDecoding(forYear: 2015)
    }

    func testDecoding2016() {
        testDecoding(forYear: 2016)
    }

    func testDecoding2017() {
        testDecoding(forYear: 2017)
    }

    func testDecoding2018() {
        testDecoding(forYear: 2018)
    }

    func testDecoding2019() {
        testDecoding(forYear: 2019)
    }

    func testDecoding2020() {
        testDecoding(forYear: 2020)
    }

    private func testDecoding(forYear year: Int) {
        let bundle = Bundle(for: DecodingTests.self)

        guard let url = bundle.url(forResource: "\(year)", withExtension: "xml"),
            let data = try? Data(contentsOf: url) else {
            return XCTFail("Unable to load schedule data for year '\(year)'")
        }

        do {
            let events = try XMLDecoder.default.decode(Schedule.self, from: data).events
            XCTAssert(events.contains { event in event.links.count > 0 })
            XCTAssert(events.contains { event in event.people.count > 0 })

            if year == 2020 {
                XCTAssert(events.contains { event in event.attachments.count > 0 })
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}

private extension Schedule {
    var events: [Event] {
        days.flatMap { day in day.events }
    }
}
