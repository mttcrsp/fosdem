@testable
import Fosdem
import XCTest

final class BuildingsServiceTests: XCTestCase {
  func testLoadBuildings() throws {
    let building = "aw"
    let data = try BundleDataLoader().data(forResource: building, withExtension: "json")

    let serviceBundle = BundleServiceMock(result: .success(data))
    let service = BuildingsService(bundleService: serviceBundle, queue: .main)
    let expectation = self.expectation(description: #function)

    service.loadBuildings { buildings, error in
      XCTAssertEqual(buildings.count, 6)
      XCTAssertNil(error)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 1)
  }

  func testLoadBuildingsMissingData() {
    let error = NSError(domain: "test", code: 1)
    let serviceBundle = BundleServiceMock(result: .failure(error))
    let service = BuildingsService(bundleService: serviceBundle, queue: .main)
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
