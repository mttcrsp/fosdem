import CoreLocation
@testable
import Fosdem

final class LocationServiceManagerMock: LocationServiceManager {
    weak var delegate: CLLocationManagerDelegate?

    var areLocationServicesEnabled: Bool = true
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var didRequestWhenInUseAuthorization: ((LocationServiceManagerMock) -> Void)?

    func requestWhenInUseAuthorization() {
        didRequestWhenInUseAuthorization?(self)
    }
}
