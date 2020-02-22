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

    func testFormatting() {
        let unformattedLicense = """
        MIT License

        Copyright (c) 2018-2019 Shawn Moore and XMLCoder contributors

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the \"Software\"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.
        """

        let formattedLicense = """
        MIT License

        Copyright (c) 2018-2019 Shawn Moore and XMLCoder contributors

        Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
        """

        let service = AcknowledgementsService()
        let license = service.makeFormattedLicense(fromLicense: unformattedLicense)
        XCTAssertEqual(license, formattedLicense)
    }
}
