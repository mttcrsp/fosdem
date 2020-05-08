@testable
import Fosdem
import XCTest

final class LocationServiceTests: XCTestCase {
    func testLocationServicesDisabled() {
        let manager = LocationServiceManagerMock()
        manager.areLocationServicesEnabled = false

        let service = LocationService(manager: manager)
        XCTAssertFalse(service.canRequestLocation)
    }

    func testRequestDenied() {
        let statuses: [CLAuthorizationStatus] = [.restricted, .denied]

        for status in statuses {
            let delegate = Delegate()
            let manager = LocationServiceManagerMock()
            manager.delegate = self
            manager.didRequestWhenInUseAuthorization = { manager in
                manager.authorizationStatus = status
            }

            let service = LocationService(manager: manager)
            XCTAssertTrue(service.canRequestLocation)

            service.requestAuthorization()
            XCTAssertTrue(delegate.didChangeStatus)
            XCTAssertFalse(service.canRequestLocation)
        }
    }

    func testRequestAuthorized() {
        let statuses: [CLAuthorizationStatus] = [.authorizedWhenInUse, .authorizedAlways]

        for status in statuses {
            let delegate = Delegate()
            let manager = LocationServiceManagerMock()
            manager.delegate = self
            manager.didRequestWhenInUseAuthorization = { manager in
                manager.authorizationStatus = status
            }

            let service = LocationService(manager: manager)
            XCTAssertTrue(service.canRequestLocation)

            service.requestAuthorization()
            XCTAssertTrue(delegate.didChangeStatus)
            XCTAssertFalse(service.canRequestLocation)
        }
    }

    final class Delegate: LocationServiceDelegate {
        private(set) var didChangeStatus = false

        func locationServiceDidChangeStatus(_: LocationService) {
            didChangeStatus = true
        }
    }
}
