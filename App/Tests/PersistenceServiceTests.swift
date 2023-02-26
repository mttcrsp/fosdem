@testable
import Fosdem
import GRDB
import XCTest

final class PersistenceServiceTests: XCTestCase {
  func testWrite() throws {
    let service = try PersistenceService(path: nil, migrations: [])
    let expectation = self.expectation(description: #function)
    let operation = Write { _ in }

    service.performWrite(operation) { error in
      XCTAssertNil(error)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 0.1)
  }

  func testWriteError() throws {
    let service = try PersistenceService(path: nil, migrations: [])
    let expectation = self.expectation(description: #function)

    let error = makeError()
    let operation = Write { _ in throw error }

    service.performWrite(operation) { receivedError in
      XCTAssertEqual(receivedError as NSError?, error)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 0.1)
  }

  func testRead() throws {
    let service = try PersistenceService(path: nil, migrations: [])
    let expectation = self.expectation(description: #function)
    let operation = Read { _ in 99 }

    service.performRead(operation) { result in
      switch result {
      case let .success(value):
        XCTAssertEqual(value, 99)
      case let .failure(error):
        XCTFail(error.localizedDescription)
      }

      expectation.fulfill()
    }

    waitForExpectations(timeout: 0.1)
  }

  func testReadError() throws {
    let service = try PersistenceService(path: nil, migrations: [])
    let expectation = self.expectation(description: #function)

    let error = makeError()
    let operation = Read { _ in throw error }

    service.performRead(operation) { result in
      switch result {
      case let .success(value):
        XCTFail("Unexpected operation success with value '\(value)'")
      case let .failure(receivedError):
        XCTAssertEqual(receivedError as NSError, error)
      }

      expectation.fulfill()
    }

    waitForExpectations(timeout: 0.1)
  }

  private func makeError() -> NSError {
    .init(domain: "com.mttcrsp.fosdem.\(String(describing: Self.self))", code: -1)
  }

  private struct Write: PersistenceServiceWrite {
    let perform: (Database) throws -> Void

    func perform(in database: Database) throws {
      try perform(database)
    }
  }

  private struct Read: PersistenceServiceRead {
    let perform: (Database) throws -> Int

    func perform(in database: Database) throws -> Int {
      try perform(database)
    }
  }
}
