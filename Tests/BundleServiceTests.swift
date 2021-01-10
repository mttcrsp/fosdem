@testable
import Fosdem
import XCTest

final class BundleServiceTests: XCTestCase {
  func testData() {
    XCTAssertNoThrow(try {
      let bundleURL = URL(fileURLWithPath: "/fosdem")
      let bundle = BundleServiceBundleMock(url: bundleURL)

      let dataProviderData = Data("something".utf8)
      let dataProvider = BundleServiceDataProviderMock(result: .success(dataProviderData))

      let resource = "resource", ext = "json"
      let service = BundleService(bundle: bundle, dataProvider: dataProvider)
      let data = try service.data(forResource: resource, withExtension: ext)

      XCTAssertEqual(data, dataProviderData)
      XCTAssertEqual(bundle.ext, ext)
      XCTAssertEqual(bundle.name, resource)
      XCTAssertEqual(dataProvider.url, bundleURL)
    }())
  }

  func testErrorData() {
    do {
      let serviceBundle = BundleServiceBundleMock(url: nil)
      let serviceDataProvider = BundleServiceDataProviderMock(result: .success(Data()))
      let service = BundleService(bundle: serviceBundle, dataProvider: serviceDataProvider)
      _ = try service.data(forResource: "resource", withExtension: "ext")
      XCTFail("Unexpectedly succeeded in loading from bundle service")
    } catch {
      let error1 = error as NSError
      let error2 = BundleService.Error.resourceNotFound as NSError
      XCTAssertEqual(error1, error2)
    }
  }

  func testErrorBundle() {
    let error1 = NSError(domain: "test", code: 1)

    do {
      let serviceBundle = BundleServiceBundleMock(url: URL(fileURLWithPath: "/fosdem"))
      let serviceDataProvider = BundleServiceDataProviderMock(result: .failure(error1))
      let service = BundleService(bundle: serviceBundle, dataProvider: serviceDataProvider)
      _ = try service.data(forResource: "resource", withExtension: "ext")
      XCTFail("Unexpectedly succeeded in loading from bundle service")
    } catch let error2 {
      let error1 = error1 as NSError
      let error2 = error2 as NSError
      XCTAssertEqual(error1, error2)
    }
  }
}
