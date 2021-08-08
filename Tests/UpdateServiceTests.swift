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
    let networkService = UpdateServiceNetworkMock()
    networkService.performHandler = { _, completion in
      completion(.success(response))
      return NetworkServiceTaskMock()
    }

    var didDetectUpdates = false
    let service = UpdateService(networkService: networkService, bundle: bundle)
    service.detectUpdates { didDetectUpdates = true }
    XCTAssertTrue(didDetectUpdates)
  }

  func testDetectUpdatesNoUpdate() {
    let bundleIdentifier = "com.mttcrsp.fosdem"
    let bundle = UpdateServiceBundleMock(bundleIdentifier: bundleIdentifier, bundleShortVersion: "1.0.0")

    let result1 = AppStoreSearchResult(bundleIdentifier: bundleIdentifier, version: "1.0.0")
    let result2 = AppStoreSearchResult(bundleIdentifier: "invalid identifier", version: "2.0.0")
    let response = AppStoreSearchResponse(results: [result1, result2])
    let networkService = UpdateServiceNetworkMock()
    networkService.performHandler = { _, completion in
      completion(.success(response))
      return NetworkServiceTaskMock()
    }

    var didDetectUpdates = false
    let service = UpdateService(networkService: networkService, bundle: bundle)
    service.detectUpdates { didDetectUpdates = true }
    XCTAssertFalse(didDetectUpdates)
  }

  func testDetectUpdatesNetworkError() {
    let bundleIdentifier = "com.mttcrsp.fosdem"
    let bundle = UpdateServiceBundleMock(bundleIdentifier: bundleIdentifier, bundleShortVersion: "1.0.0")

    let networkServiceError = NSError(domain: "com.mttcrsp.fosdem", code: 1)
    let networkService = UpdateServiceNetworkMock()
    networkService.performHandler = { _, completion in
      completion(.failure(networkServiceError))
      return NetworkServiceTaskMock()
    }

    var didDetectUpdates = false
    let service = UpdateService(networkService: networkService, bundle: bundle)
    service.detectUpdates { didDetectUpdates = true }
    XCTAssertFalse(didDetectUpdates)
  }
}
