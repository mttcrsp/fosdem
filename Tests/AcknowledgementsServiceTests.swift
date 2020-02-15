@testable
import Fosdem
import XCTest

final class AcknowledgementsServiceTests: XCTestCase {
    func testLoadAcknoledements() {
        let service = AcknowledgementsService(bundle: bundle)
        let acknowledgements = service.loadAcknowledgements()
        XCTAssertEqual(acknowledgements, ["XMLCoder"])
    }

    func testLoadLicense() {
        let service = AcknowledgementsService(bundle: bundle)
        let license = service.loadLicense(for: "XMLCoder")
        XCTAssertEqual(license?.count ?? 0, 1098)
    }
}
