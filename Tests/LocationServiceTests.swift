import CoreLocation
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

    func testRequestAuthorization() {
        let statuses: [CLAuthorizationStatus] = [.restricted, .denied, .authorizedWhenInUse, .authorizedAlways]

        for status in statuses {
            let delegate = Delegate()
            let manager = LocationServiceManagerMock()
            manager.didRequestWhenInUseAuthorization = { manager in
                manager.authorizationStatus = status
                manager.delegate?.locationManager?(CLLocationManager(), didChangeAuthorization: status)
            }

            let service = LocationService(manager: manager)
            service.delegate = delegate
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
