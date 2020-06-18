import XCTest

extension XCTNSPredicateExpectation {
  convenience init(predicate block: @escaping () -> Bool) {
    let predicate = NSPredicate(block: { _, _ in block() })
    self.init(predicate: predicate, object: nil)
  }
}
