import Combine
import CoreLocation
import UIKit

final class MapViewModel: NSObject {
  typealias Dependencies = HasBuildingsService & HasOpenService

  let didFail = PassthroughSubject<Error, Never>()
  @Published private(set) var authorizationStatus: CLAuthorizationStatus = .denied
  @Published private(set) var buildings: [Building] = []
  private let locationManager = CLLocationManager()
  private let dependencies: Dependencies

  init(dependencies: Dependencies) {
    self.dependencies = dependencies
  }

  func didLoad() {
    locationManager.delegate = self
    authorizationStatus = locationManager.authorizationStatus

    dependencies.buildingsService.loadBuildings { [weak self] buildings, error in
      if let error {
        self?.didFail.send(error)
      } else {
        self?.buildings = buildings
      }
    }
  }

  func didSelectLocation() {
    locationManager.requestWhenInUseAuthorization()
  }

  func didSelectLocationSettings() {
    if let url = URL(string: UIApplication.openSettingsURLString) {
      dependencies.openService.open(url, completion: nil)
    }
  }
}

extension MapViewModel: CLLocationManagerDelegate {
  func locationManager(_: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    authorizationStatus = status
  }
}
