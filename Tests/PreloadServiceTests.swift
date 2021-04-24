@testable
import Fosdem
import XCTest

final class PreloadServiceTests: XCTestCase {
  func testInitResourceNotFoundError() {
    do {
      let bundle = PreloadServiceBundleMock()
      bundle.pathHandler = { _, _ in nil }

      let fileManagerURL = URL(fileURLWithPath: "/documents")
      let fileManager = PreloadServiceFileMock()
      fileManager.fileExistsHandler = { _ in false }
      fileManager.urlHandler = { _, _, _, _ in fileManagerURL }

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
      let bundle = PreloadServiceBundleMock()
      bundle.pathHandler = { _, _ in "/bundle" }

      let fileManager = PreloadServiceFileMock()
      fileManager.fileExistsHandler = { _ in false }
      fileManager.urlHandler = { _, _, _, _ in throw fileManagerError }

      _ = try PreloadService(bundle: bundle, fileManager: fileManager)
      XCTFail("Unexpectedly succeeded in initialising from bundle service")
    } catch {
      let error1 = error as NSError
      let error2 = fileManagerError
      XCTAssertEqual(error1, error2)
    }
  }

  func testDatabasePath() throws {
    let bundle = PreloadServiceBundleMock()
    bundle.pathHandler = { _, _ in "/bundle" }

    let fileManagerURL = URL(fileURLWithPath: "/documents")
    let fileManager = PreloadServiceFileMock()
    fileManager.fileExistsHandler = { _ in false }
    fileManager.urlHandler = { _, _, _, _ in fileManagerURL }

    let service = try PreloadService(bundle: bundle, fileManager: fileManager)
    XCTAssertEqual(service.databasePath, "/documents/db.sqlite")
  }

  func testPreloadDatabaseIfNeeded() throws {
    let bundle = PreloadServiceBundleMock()
    bundle.pathHandler = { _, _ in "/bundle" }

    let fileManagerURL = URL(fileURLWithPath: "/documents")
    let fileManager = PreloadServiceFileMock()
    fileManager.fileExistsHandler = { _ in false }
    fileManager.urlHandler = { _, _, _, _ in fileManagerURL }

    let service = try PreloadService(bundle: bundle, fileManager: fileManager)
    try service.preloadDatabaseIfNeeded()

    XCTAssertEqual(fileManager.copyItemCallCount, 1)
    XCTAssertEqual(fileManager.copyItemArgValues.first?.0, "/bundle")
    XCTAssertEqual(fileManager.copyItemArgValues.first?.1, "/documents/db.sqlite")
  }

  func testPreloadDatabaseIfNeededFileExists() throws {
    let bundle = PreloadServiceBundleMock()
    bundle.pathHandler = { _, _ in "/bundle" }

    let fileManagerURL = URL(fileURLWithPath: "/documents")
    let fileManager = PreloadServiceFileMock()
    fileManager.fileExistsHandler = { _ in true }
    fileManager.urlHandler = { _, _, _, _ in fileManagerURL }

    let service = try PreloadService(bundle: bundle, fileManager: fileManager)
    try service.preloadDatabaseIfNeeded()

    XCTAssertEqual(fileManager.copyItemCallCount, 0)
  }

  func testPreloadDatabaseIfNeededCopyItemError() {
    let fileManagerError = NSError(domain: "test", code: 1)

    do {
      let bundle = PreloadServiceBundleMock()
      bundle.pathHandler = { _, _ in "/bundle" }

      let fileManagerURL = URL(fileURLWithPath: "/documents")
      let fileManager = PreloadServiceFileMock()
      fileManager.fileExistsHandler = { _ in false }
      fileManager.copyItemHandler = { _, _ in throw fileManagerError }
      fileManager.urlHandler = { _, _, _, _ in fileManagerURL }

      let service = try PreloadService(bundle: bundle, fileManager: fileManager)
      try service.preloadDatabaseIfNeeded()
      XCTFail("Unexpectedly succeeded in preloading database")
    } catch {
      let error1 = error as NSError
      let error2 = fileManagerError
      XCTAssertEqual(error1, error2)
    }
  }

  func testRemoveDatabase() throws {
    let bundle = PreloadServiceBundleMock()
    bundle.pathHandler = { _, _ in "/bundle" }

    let fileManagerURL = URL(fileURLWithPath: "/documents")
    let fileManager = PreloadServiceFileMock()
    fileManager.fileExistsHandler = { _ in false }
    fileManager.urlHandler = { _, _, _, _ in fileManagerURL }

    let service = try PreloadService(bundle: bundle, fileManager: fileManager)
    try service.removeDatabase()

    XCTAssertEqual(fileManager.removeItemArgValues, ["/documents/db.sqlite"])
  }

  func testRemoveDatabaseError() {
    let fileManagerError = NSError(domain: "test", code: 1)

    do {
      let bundle = PreloadServiceBundleMock()
      bundle.pathHandler = { _, _ in "/bundle" }

      let fileManagerURL = URL(fileURLWithPath: "/documents")
      let fileManager = PreloadServiceFileMock()
      fileManager.fileExistsHandler = { _ in false }
      fileManager.removeItemHandler = { _ in throw fileManagerError }
      fileManager.urlHandler = { _, _, _, _ in fileManagerURL }

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
