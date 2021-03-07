@testable
import Core
import XCTest

final class PreloadServiceTests: XCTestCase {
  func testInitResourceNotFoundError() {
    do {
      let bundlePath: String? = nil
      let bundle = PreloadServiceBundleMock(path: bundlePath)
      let fileManagerURL = URL(fileURLWithPath: "/documents")
      let fileManager = PreloadServiceFileMock(fileExists: false, copyItemResult: .success(()), removeItemResult: .success(()), urlResult: .success(fileManagerURL))
      _ = try PreloadService(bundle: bundle, fileManager: fileManager)
      XCTFail("Unexpectedly succeeded in initialising from bundle service")
    } catch {
      let error1 = error as NSError
      let error2 = PreloadService.Error.resourceNotFound as NSError
      XCTAssertEqual(error1, error2)
    }
  }

  func testInitURLError() {
    let fileManagerError = NSError(domain: "test", code: 1)

    do {
      let bundle = PreloadServiceBundleMock(path: "/bundle")
      let fileManager = PreloadServiceFileMock(fileExists: false, copyItemResult: .success(()), removeItemResult: .success(()), urlResult: .failure(fileManagerError))
      _ = try PreloadService(bundle: bundle, fileManager: fileManager)
      XCTFail("Unexpectedly succeeded in initialising from bundle service")
    } catch {
      let error1 = error as NSError
      let error2 = fileManagerError
      XCTAssertEqual(error1, error2)
    }
  }

  func testDatabasePath() {
    XCTAssertNoThrow(try {
      let bundle = PreloadServiceBundleMock(path: "/bundle")
      let fileManagerURL = URL(fileURLWithPath: "/documents")
      let fileManager = PreloadServiceFileMock(fileExists: false, copyItemResult: .success(()), removeItemResult: .success(()), urlResult: .success(fileManagerURL))
      let service = try PreloadService(bundle: bundle, fileManager: fileManager)
      XCTAssertEqual(service.databasePath, "/documents/db.sqlite")
    }())
  }

  func testPreloadDatabaseIfNeeded() {
    XCTAssertNoThrow(try {
      let bundle = PreloadServiceBundleMock(path: "/bundle")
      let fileManagerURL = URL(fileURLWithPath: "/documents")
      let fileManager = PreloadServiceFileMock(fileExists: false, copyItemResult: .success(()), removeItemResult: .success(()), urlResult: .success(fileManagerURL))
      let service = try PreloadService(bundle: bundle, fileManager: fileManager)
      try service.preloadDatabaseIfNeeded()
      XCTAssertEqual(fileManager.oldPath, "/bundle")
      XCTAssertEqual(fileManager.newPath, "/documents/db.sqlite")
    }())
  }

  func testPreloadDatabaseIfNeededFileExists() {
    XCTAssertNoThrow(try {
      let bundle = PreloadServiceBundleMock(path: "/bundle")
      let fileManagerURL = URL(fileURLWithPath: "/documents")
      let fileManager = PreloadServiceFileMock(fileExists: true, copyItemResult: .success(()), removeItemResult: .success(()), urlResult: .success(fileManagerURL))
      let service = try PreloadService(bundle: bundle, fileManager: fileManager)
      try service.preloadDatabaseIfNeeded()
      XCTAssertNil(fileManager.oldPath)
      XCTAssertNil(fileManager.newPath)
    }())
  }

  func testPreloadDatabaseIfNeededCopyItemError() {
    let fileManagerError = NSError(domain: "test", code: 1)

    do {
      let bundle = PreloadServiceBundleMock(path: "/bundle")
      let fileManagerURL = URL(fileURLWithPath: "/documents")
      let fileManager = PreloadServiceFileMock(fileExists: false, copyItemResult: .failure(fileManagerError), removeItemResult: .success(()), urlResult: .success(fileManagerURL))
      let service = try PreloadService(bundle: bundle, fileManager: fileManager)
      try service.preloadDatabaseIfNeeded()
      XCTFail("Unexpectedly succeeded in preloading database")
    } catch {
      let error1 = error as NSError
      let error2 = fileManagerError
      XCTAssertEqual(error1, error2)
    }
  }

  func testRemoveDatabase() {
    XCTAssertNoThrow(try {
      let bundle = PreloadServiceBundleMock(path: "/bundle")
      let fileManagerURL = URL(fileURLWithPath: "/documents")
      let fileManager = PreloadServiceFileMock(fileExists: false, copyItemResult: .success(()), removeItemResult: .success(()), urlResult: .success(fileManagerURL))
      let service = try PreloadService(bundle: bundle, fileManager: fileManager)
      try service.removeDatabase()
      XCTAssertEqual(fileManager.path, "/documents/db.sqlite")
    }())
  }

  func testRemoveDatabaseError() {
    let fileManagerError = NSError(domain: "test", code: 1)

    do {
      let bundle = PreloadServiceBundleMock(path: "/bundle")
      let fileManagerURL = URL(fileURLWithPath: "/documents")
      let fileManager = PreloadServiceFileMock(fileExists: false, copyItemResult: .success(()), removeItemResult: .failure(fileManagerError), urlResult: .success(fileManagerURL))
      let service = try PreloadService(bundle: bundle, fileManager: fileManager)
      try service.removeDatabase()
      XCTFail("Unexpectedly succeeded in preloading database")
    } catch {
      let error1 = error as NSError
      let error2 = fileManagerError
      XCTAssertEqual(error1, error2)
    }
  }
}
