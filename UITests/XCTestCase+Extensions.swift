import XCTest

extension XCTestCase {
  func runActivity(named: String, block: () -> Void) {
    XCTContext.runActivity(named: named) { _ in block() }
  }

  func wait(for predicate: @escaping () -> Bool, timeout: TimeInterval = 3) {
    let predicate = NSPredicate { _, _ in predicate() }
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
    XCTWaiter().wait(for: [expectation], timeout: timeout)
  }
}
