@testable
import Fosdem
import XCTest

final class AcknowledgementsServiceTests: XCTestCase {
    func testLoadAcknoledements() {
        let bundle = AcknowledgementsServiceBundleMock(path: "path")
        let plist = AcknowledgementsServicePlistMock(dictionary: [
            "PreferenceSpecifiers": [
                ["Title": "1", "File": "test"],
                ["Title": "2", "File": "test"],
            ],
        ])

        let service = AcknowledgementsService(bundle: bundle, plist: plist)
        let acknowledgements = service.loadAcknowledgements()

        XCTAssertEqual(plist.path, "path")
        XCTAssertEqual(bundle.ext, "plist")
        XCTAssertEqual(bundle.name, "Licenses")
        XCTAssertEqual(acknowledgements, ["1", "2"])
    }

    func testMissingAcknowledmentsFile() {
        let bundle = AcknowledgementsServiceBundleMock(path: nil)
        let plist = AcknowledgementsServicePlistMock(dictionary: nil)

        let service = AcknowledgementsService(bundle: bundle, plist: plist)
        let acknowledgements = service.loadAcknowledgements()
        XCTAssertEqual(acknowledgements, [])
    }

    func testInvalidAcknowledmentsFormat() {
        let bundle = AcknowledgementsServiceBundleMock(path: "path")
        let plist = AcknowledgementsServicePlistMock(dictionary: ["invalid": "invalid"])

        let service = AcknowledgementsService(bundle: bundle, plist: plist)
        let acknowledgements = service.loadAcknowledgements()
        XCTAssertEqual(acknowledgements, [])
    }

    func testLoadLicense() {
        let bundle = AcknowledgementsServiceBundleMock(path: "path")
        let plist = AcknowledgementsServicePlistMock(dictionary: [
            "PreferenceSpecifiers": [["FooterText": "\n\tlicense   \n"]],
        ])

        let service = AcknowledgementsService(bundle: bundle, plist: plist)
        let license = service.loadLicense(for: "XMLCoder")

        XCTAssertEqual(license, "license")
        XCTAssertEqual(plist.path, "path")
        XCTAssertEqual(bundle.ext, "plist")
        XCTAssertEqual(bundle.name, "XMLCoder")
    }

    func testMissingLicenseFile() {
        let bundle = AcknowledgementsServiceBundleMock(path: nil)
        let plist = AcknowledgementsServicePlistMock(dictionary: nil)

        let service = AcknowledgementsService(bundle: bundle, plist: plist)
        let license = service.loadLicense(for: "XMLCoder")
        XCTAssertNil(license)
    }

    func testInvalidLicenseFile() {
        let bundle = AcknowledgementsServiceBundleMock(path: "path")
        let plist = AcknowledgementsServicePlistMock(dictionary: [
            "PreferenceSpecifiers": [["invalid": "invalid"]],
        ])

        let service = AcknowledgementsService(bundle: bundle, plist: plist)
        let license = service.loadLicense(for: "XMLCoder")
        XCTAssertNil(license)
    }
}
