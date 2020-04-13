@testable
import Fosdem
import XCTest

final class PreloadServiceTests: XCTestCase {
    func testInitResourceNotFoundError() {
        do {
            let bundlePath: String? = nil
            let bundle = PreloadServiceBundleMock(path: bundlePath)
            let fileManagerURL = URL(fileURLWithPath: "/documents")
            let fileManager = PreloadServiceFileMock(fileExists: false, moveItemResult: .success(()), urlResult: .success(fileManagerURL))

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
            let fileManager = PreloadServiceFileMock(fileExists: false, moveItemResult: .success(()), urlResult: .failure(fileManagerError))

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
            let fileManagerURL = URL(fileURLWithPath: "/documents")
            let fileManager = PreloadServiceFileMock(fileExists: false, moveItemResult: .success(()), urlResult: .success(fileManagerURL))
            let bundle = PreloadServiceBundleMock(path: "/bundle")

            let service = try PreloadService(bundle: bundle, fileManager: fileManager)
            XCTAssertEqual(service.databasePath, "/documents/db.sqlite")
        }())
    }

    func testPreloadDatabaseIfNeeded() {
        XCTAssertNoThrow(try {
            let fileManagerURL = URL(fileURLWithPath: "/documents")
            let fileManager = PreloadServiceFileMock(fileExists: false, moveItemResult: .success(()), urlResult: .success(fileManagerURL))
            let bundle = PreloadServiceBundleMock(path: "/bundle")
            let service = try PreloadService(bundle: bundle, fileManager: fileManager)

            try service.preloadDatabaseIfNeeded()
            XCTAssertEqual(fileManager.oldPath, "/bundle")
            XCTAssertEqual(fileManager.newPath, "/documents/db.sqlite")
        }())
    }

    func testPreloadDatabaseIfNeededFileExists() {
        XCTAssertNoThrow(try {
            let fileManagerURL = URL(fileURLWithPath: "/documents")
            let fileManager = PreloadServiceFileMock(fileExists: true, moveItemResult: .success(()), urlResult: .success(fileManagerURL))
            let bundle = PreloadServiceBundleMock(path: "/bundle")
            let service = try PreloadService(bundle: bundle, fileManager: fileManager)

            try service.preloadDatabaseIfNeeded()
            XCTAssertNil(fileManager.oldPath)
            XCTAssertNil(fileManager.newPath)
        }())
    }

    func testPreloadDatabaseIfNeededMoveItemError() {
        let fileManagerError = NSError(domain: "test", code: 1)

        do {
            let fileManagerURL = URL(fileURLWithPath: "/documents")
            let fileManager = PreloadServiceFileMock(fileExists: false, moveItemResult: .failure(fileManagerError), urlResult: .success(fileManagerURL))
            let bundle = PreloadServiceBundleMock(path: "/bundle")
            let service = try PreloadService(bundle: bundle, fileManager: fileManager)

            try service.preloadDatabaseIfNeeded()
            XCTFail("Unexpectedly succeeded in preloading database")
        } catch {
            let error1 = error as NSError
            let error2 = fileManagerError
            XCTAssertEqual(error1, error2)
        }
    }
}
