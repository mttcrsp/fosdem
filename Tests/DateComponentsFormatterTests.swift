@testable
import Fosdem
import XCTest

final class DateComponentsFormatterTests: XCTestCase {
  func testTime() {
    let formatter = DateComponentsFormatter.time
    XCTAssertEqual(formatter.string(from: .init(hour: 9, minute: 0)), "9:00")
    XCTAssertEqual(formatter.string(from: .init(hour: 23, minute: 59)), "23:59")
  }
}
