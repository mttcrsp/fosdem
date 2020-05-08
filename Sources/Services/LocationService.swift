import CoreLocation

protocol LocationServiceManager: AnyObject {
    var areLocationServicesEnabled: Bool { get }
    var authorizationStatus: CLAuthorizationStatus { get }
    var delegate: CLLocationManagerDelegate? { get set }

    func requestWhenInUseAuthorization()
}

protocol LocationServiceDelegate: AnyObject {
    func locationServiceDidChangeStatus(_ locationService: LocationService)
}

final class LocationService: NSObject {
    weak var delegate: LocationServiceDelegate?

    var canRequestLocation: Bool {
        manager.areLocationServicesEnabled && manager.authorizationStatus == .notDetermined
    }

    private let manager: LocationServiceManager

    init(manager: LocationServiceManager = CLLocationManager()) {
        self.manager = manager
        super.init()
        self.manager.delegate = self
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_: CLLocationManager, didChangeAuthorization _: CLAuthorizationStatus) {
        delegate?.locationServiceDidChangeStatus(self)
    }
}

extension CLLocationManager: LocationServiceManager {
    var areLocationServicesEnabled: Bool {
        CLLocationManager.locationServicesEnabled()
    }

    var authorizationStatus: CLAuthorizationStatus {
        CLLocationManager.authorizationStatus()
    }
}
