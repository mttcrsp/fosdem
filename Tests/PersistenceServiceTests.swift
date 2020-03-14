@testable
import Fosdem
import GRDB
import XCTest

final class PersistenceServiceTests: XCTestCase {
    func testWrite() {
        XCTAssertNoThrow(try {
            let service = try PersistenceService(path: nil, migrations: [])
            let expectation = self.expectation(description: #function)
            let operation = Write { _ in }

            service.performWrite(operation) { error in
                expectation.fulfill()
                XCTAssertNil(error)
            }

            self.waitForExpectations(timeout: 0.1)
        }())
    }

    func testWriteError() {
        XCTAssertNoThrow(try {
            let service = try PersistenceService(path: nil, migrations: [])
            let expectation = self.expectation(description: #function)
            let error = NSError(domain: "org.fosdem.fosdem", code: -1)
            let operation = Write { _ in throw error }

            service.performWrite(operation) { receivedError in
                expectation.fulfill()
                XCTAssertEqual(receivedError as NSError?, error)
            }

            self.waitForExpectations(timeout: 0.1)
        }())
    }

    private struct Write: PersistenceServiceWrite {
        let perform: (Database) throws -> Void

        func perform(in database: Database) throws {
            try perform(database)
        }
    }
}
