@testable
import Fosdem
import XCTest

final class AcknowledgementsServiceTests: XCTestCase {
  func testLoadAcknowledgements() throws {
    let data = Data("""
    [
        {"name":"a","url":"https://fosdem.org/a"},
        {"name":"b","url":"https://fosdem.org/b"}
    ]
    """.utf8)

    let dataProvider = AcknowledgementsServiceDataProviderMock()
    dataProvider.dataHandler = { _ in data }

    let bundle = AcknowledgementsServiceBundleMock()
    bundle.urlHandler = { _, _ in URL(fileURLWithPath: "/fosdem") }

    let service = AcknowledgementsService(bundle: bundle, dataProvider: dataProvider)

    let acknowledgements1 = try service.loadAcknowledgements()
    let acknowledgements2 = [
      Acknowledgement(name: "a", url: URL(string: "https://fosdem.org/a")!),
      Acknowledgement(name: "b", url: URL(string: "https://fosdem.org/b")!),
    ]
    XCTAssertEqual(acknowledgements1, acknowledgements2)
  }

  func testLoadAcknowledgementsBundleError() {
    do {
      let dataProvider = AcknowledgementsServiceDataProviderMock()
      dataProvider.dataHandler = { _ in Data() }

      let bundle = AcknowledgementsServiceBundleMock()
      bundle.urlHandler = { _, _ in nil }

      let service = AcknowledgementsService(bundle: bundle, dataProvider: dataProvider)
      _ = try service.loadAcknowledgements()
      XCTFail("Unexpectedly succeeded in loading acknowledgements")
    } catch {
      let error1 = error as NSError
      let error2 = AcknowledgementsService.Error.resourceNotFound as NSError
      XCTAssertEqual(error1, error2)
    }
  }

  func testLoadAcknowledgementsDataError() {
    let error1 = NSError(domain: "test", code: 1)

    do {
      let dataProvider = AcknowledgementsServiceDataProviderMock()
      dataProvider.dataHandler = { _ in throw error1 }

      let bundle = AcknowledgementsServiceBundleMock()
      bundle.urlHandler = { _, _ in URL(fileURLWithPath: "/fosdem") }

      let service = AcknowledgementsService(bundle: bundle, dataProvider: dataProvider)
      _ = try service.loadAcknowledgements()
      XCTFail("Unexpectedly succeeded in loading acknowledgements")
    } catch let error2 {
      let error1 = error1 as NSError
      let error2 = error2 as NSError
      XCTAssertEqual(error1, error2)
    }
  }

  func testloadAcknowledgementsDecodingError() {
    do {
      let dataProvider = AcknowledgementsServiceDataProviderMock() // (data: .success(data))
      dataProvider.dataHandler = { _ in Data() }

      let bundle = AcknowledgementsServiceBundleMock()
      bundle.urlHandler = { _, _ in URL(fileURLWithPath: "/fosdem") }

      let service = AcknowledgementsService(bundle: bundle, dataProvider: dataProvider)
      _ = try service.loadAcknowledgements()
      XCTFail("Unexpectedly succeeded in loading acknowledgements")
    } catch {
      XCTAssert(error is DecodingError)
    }
  }
}
