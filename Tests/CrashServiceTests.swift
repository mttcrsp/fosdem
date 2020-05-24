@testable
import Fosdem
import XCTest

final class CrashServiceTests: XCTestCase {
    func testInit() {
        let networkService = CrashServiceNetworkMock()
        let reporter = CrashServiceReporterMock(canEnable: false, canPurge: false, hasReport: false, loadReportData: nil)
        let service = CrashService(networkService: networkService, reporter: reporter, secretKey: "key")

        XCTAssertNil(service)
    }

    func testUploadReport() {
        let networkService = CrashServiceNetworkMock()
        let reporterData = Data(repeating: 1, count: 10)
        let reporter = CrashServiceReporterMock(canEnable: true, canPurge: true, hasReport: true, loadReportData: reporterData)

        let service = CrashService(networkService: networkService, reporter: reporter, secretKey: "key")
        XCTAssertNotNil(service)
        XCTAssertEqual(service?.hasPendingReport, true)

        let allHTTPHeaderFields = ["secret-key": "key", "Content-Type": "application/json"]

        service?.uploadReport()
        XCTAssertTrue(reporter.didLoad)
        XCTAssertFalse(reporter.didPurge)
        XCTAssertEqual(networkService.request?.httpMethod, "POST")
        XCTAssertEqual(networkService.request?.httpBody?.count, 29)
        XCTAssertEqual(networkService.request?.url, URL(string: "https://api.jsonbin.io/b"))
        XCTAssertEqual(networkService.request?.allHTTPHeaderFields, allHTTPHeaderFields)
    }

    func testHasReport() {
        let networkService = CrashServiceNetworkMock()
        let reporter = CrashServiceReporterMock(canEnable: true, canPurge: false, hasReport: false, loadReportData: nil)

        let service = CrashService(networkService: networkService, reporter: reporter)
        XCTAssertNotNil(service)
        XCTAssertEqual(service?.hasPendingReport, false)

        service?.uploadReport()
        XCTAssertFalse(reporter.didLoad)
        XCTAssertFalse(reporter.didPurge)
        XCTAssertNil(networkService.request)
    }

    func testPurgeReport() {
        let networkService = CrashServiceNetworkMock()
        let reporter = CrashServiceReporterMock(canEnable: true, canPurge: true, hasReport: true, loadReportData: nil)

        let service = CrashService(networkService: networkService, reporter: reporter)
        service?.purgeReport()
        XCTAssertTrue(reporter.didPurge)
    }
}
