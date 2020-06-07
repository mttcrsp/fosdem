@testable
import Fosdem
import XCTest

final class UpdateServiceTests: XCTestCase {
  func testDetectUpdates() {
    let bundleIdentifier = "com.mttcrsp.fosdem"
    let bundle = UpdateServiceBundleMock(bundleIdentifier: bundleIdentifier, bundleShortVersion: "1.0.0")

    let result1 = AppStoreSearchResult(bundleIdentifier: "invalid identifier", version: "invalid version")
    let result2 = AppStoreSearchResult(bundleIdentifier: bundleIdentifier, version: "1.1.1")
    let response = AppStoreSearchResponse(results: [result1, result2])
    let networkService = UpdateServiceNetworkMock(result: .success(response))

    let delegate = Delegate()
    let service = UpdateService(networkService: networkService, bundle: bundle)
    service.delegate = delegate
    service.detectUpdates()

    XCTAssertTrue(delegate.didUpdate)
  }

  func testDetectUpdatesNoUpdate() {
    let bundleIdentifier = "com.mttcrsp.fosdem"
    let bundle = UpdateServiceBundleMock(bundleIdentifier: bundleIdentifier, bundleShortVersion: "1.0.0")

    let result1 = AppStoreSearchResult(bundleIdentifier: bundleIdentifier, version: "1.0.0")
    let result2 = AppStoreSearchResult(bundleIdentifier: "invalid identifier", version: "2.0.0")
    let response = AppStoreSearchResponse(results: [result1, result2])
    let networkService = UpdateServiceNetworkMock(result: .success(response))

    let delegate = Delegate()
    let service = UpdateService(networkService: networkService, bundle: bundle)
    service.delegate = delegate
    service.detectUpdates()

    XCTAssertFalse(delegate.didUpdate)
  }

  func testDetectUpdatesNetworkError() {
    let bundleIdentifier = "com.mttcrsp.fosdem"
    let bundle = UpdateServiceBundleMock(bundleIdentifier: bundleIdentifier, bundleShortVersion: "1.0.0")

    let networkServiceError = NSError(domain: "com.mttcrsp.fosdem", code: 1)
    let networkService = UpdateServiceNetworkMock(result: .failure(networkServiceError))

    let delegate = Delegate()
    let service = UpdateService(networkService: networkService, bundle: bundle)
    service.delegate = delegate
    service.detectUpdates()

    XCTAssertFalse(delegate.didUpdate)
  }

  private final class Delegate: UpdateServiceDelegate {
    var didUpdate = false

    func updateServiceDidDetectUpdate(_ updateService: UpdateService) {
      didUpdate = true
    }
  }
}
