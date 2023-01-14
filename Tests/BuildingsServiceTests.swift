@testable
import Fosdem
import XCTest

final class BuildingsServiceTests: XCTestCase {
  func testLoadBuildings() throws {
    let building = "aw"
    let data = try BundleDataLoader().data(forResource: building, withExtension: "json")

    let bundle = BuildingsServiceBundleMock()
    bundle.dataHandler = { _, _ in data }

    let service = BuildingsService(bundleService: bundle, queue: .main)
    let expectation = self.expectation(description: #function)

    service.loadBuildings { buildings, error in
      XCTAssertEqual(buildings.count, 7)
      XCTAssertNil(error)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 1)
  }

  func testLoadBuildingsMissingData() {
    let error = NSError(domain: "test", code: 1)
    let bundle = BuildingsServiceBundleMock()
    bundle.dataHandler = { _, _ in throw error }

    let service = BuildingsService(bundleService: bundle, queue: .main)
    let expectation = self.expectation(description: #function)

    service.loadBuildings { buildings, error in
      let error1 = error as NSError?
      let error2 = BuildingsService.Error.missingData as NSError

      XCTAssertTrue(buildings.isEmpty)
      XCTAssertEqual(error1, error2)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 1)
  }
}
