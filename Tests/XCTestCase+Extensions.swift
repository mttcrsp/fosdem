import XCTest

extension XCTestCase {
    var bundle: Bundle {
        Bundle(for: Self.self)
    }
}
