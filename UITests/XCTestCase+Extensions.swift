import XCTest

extension XCTestCase {
  func runActivity(named: String, block: () -> Void) {
    XCTContext.runActivity(named: named) { _ in block() }
  }

  func wait(file: StaticString = #file, line: UInt = #line, timeout: TimeInterval = 10, for predicate: @escaping () -> Bool) {
    let expectation = XCTNSPredicateExpectation(predicate: predicate)
    if XCTWaiter().wait(for: [expectation], timeout: timeout) != .completed {
      XCTFail("Expectation failed", file: file, line: line)
    }
  }
}
