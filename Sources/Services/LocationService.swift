import CoreLocation

final class LocationService: NSObject {
  private let notificationCenter = NotificationCenter()
  private let locationManager: CLLocationManager

  init(locationManager: CLLocationManager = .init()) {
    self.locationManager = locationManager
    super.init()
    self.locationManager.delegate = self
  }

  var authorizationStatus: CLAuthorizationStatus {
    CLLocationManager.authorizationStatus()
  }

  func requestAuthorization() {
    locationManager.requestWhenInUseAuthorization()
  }

  func addObserverForStatus(_ handler: @escaping (CLAuthorizationStatus) -> Void) -> NSObjectProtocol {
    notificationCenter.addObserver(forName: .authorizationStatusDidChange, object: nil, queue: nil) { [weak self] _ in
      if let self = self {
        handler(self.authorizationStatus)
      }
    }
  }

  func removeObserver(_ observer: NSObjectProtocol) {
    notificationCenter.removeObserver(observer)
  }
}

extension LocationService: CLLocationManagerDelegate {
  func locationManager(_: CLLocationManager, didChangeAuthorization _: CLAuthorizationStatus) {
    notificationCenter.post(name: .authorizationStatusDidChange, object: nil)
  }
}

private extension Notification.Name {
  static var authorizationStatusDidChange: Notification.Name { Notification.Name(#function) }
}

/// @mockable
protocol LocationServiceProtocol {
  var authorizationStatus: CLAuthorizationStatus { get }
  func requestAuthorization()
  func addObserverForStatus(_ handler: @escaping (CLAuthorizationStatus) -> Void) -> NSObjectProtocol
  func removeObserver(_ observer: NSObjectProtocol)
}

extension LocationService: LocationServiceProtocol {}
