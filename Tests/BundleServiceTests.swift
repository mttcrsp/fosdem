@testable
import Fosdem
import XCTest

final class BundleServiceTests: XCTestCase {
  func testData() throws {
    let bundleURL = URL(fileURLWithPath: "/fosdem")
    let bundle = BundleServiceBundleMock()
    bundle.urlHandler = { _, _ in bundleURL }

    let dataProviderData = Data("something".utf8)
    let dataProvider = BundleServiceDataProviderMock()
    dataProvider.dataHandler = { _ in dataProviderData }

    let resource = "resource", ext = "json"
    let service = BundleService(bundle: bundle, dataProvider: dataProvider)
    let data = try service.data(forResource: resource, withExtension: ext)

    XCTAssertEqual(data, dataProviderData)
    XCTAssertEqual(bundle.urlCallCount, 1)
    XCTAssertEqual(bundle.urlArgValues.first?.1, ext)
    XCTAssertEqual(bundle.urlArgValues.first?.0, resource)
    XCTAssertEqual(dataProvider.dataCallCount, 1)
    XCTAssertEqual(dataProvider.dataArgValues.first, bundleURL)
  }

  func testErrorData() {
    do {
      let bundle = BundleServiceBundleMock()
      bundle.urlHandler = { _, _ in nil }

      let dataProvider = BundleServiceDataProviderMock()
      dataProvider.dataHandler = { _ in Data() }

      let service = BundleService(bundle: bundle, dataProvider: dataProvider)
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
      let bundle = BundleServiceBundleMock()
      bundle.urlHandler = { _, _ in URL(fileURLWithPath: "/fosdem") }

      let dataProvider = BundleServiceDataProviderMock()
      dataProvider.dataHandler = { _ in throw error1 }

      let service = BundleService(bundle: bundle, dataProvider: dataProvider)
      _ = try service.data(forResource: "resource", withExtension: "ext")
      XCTFail("Unexpectedly succeeded in loading from bundle service")
    } catch let error2 {
      let error1 = error1 as NSError
      let error2 = error2 as NSError
      XCTAssertEqual(error1, error2)
    }
  }
}
