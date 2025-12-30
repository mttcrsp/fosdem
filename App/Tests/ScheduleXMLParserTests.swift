@testable
import Fosdem
import XCTest

final class ScheduleXMLParserTests: XCTestCase {
  func testDecoding() throws {
    for year in 2007 ... 2026 {
      let data = try data(forYear: year)
      let parser = ScheduleXMLParser(data: data)
      XCTAssert(parser.parse())
      XCTAssertNil(parser.parseError)
      XCTAssertNil(parser.validationError)

      let schedule = try XCTUnwrap(parser.schedule)
      XCTAssertGreaterThan(schedule.days.last?.events.count ?? 0, 0)
      XCTAssertGreaterThan(schedule.days.first?.events.count ?? 0, 0)
    }
  }

  func testLinks() throws {
    let data = try data(forYear: 2023)
    let parser = ScheduleXMLParser(data: data)
    XCTAssert(parser.parse())

    let schedule = try XCTUnwrap(parser.schedule)
    let validLinks = schedule.days
      .flatMap(\.events)
      .flatMap(\.links)
      .filter { link in link.url != nil }
    XCTAssertEqual(validLinks.count, 4962)
  }

  private func data(forYear year: Int) throws -> Data {
    try XCTUnwrap(BundleDataLoader().data(forResource: "\(year)", withExtension: "xml"))
  }
}
