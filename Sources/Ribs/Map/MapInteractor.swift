import CoreLocation
import RIBs
import UIKit

protocol MapListener: AnyObject {
  func mapDidError(_ error: Error)
}

protocol MapPresentable: Presentable {
  var authorizationStatus: CLAuthorizationStatus { get set }
  var buildings: [Building] { get set }
  func showAction(_ action: CLAuthorizationStatus.Action)
}

class MapInteractor: PresentableInteractor<MapPresentable> {
  weak var listener: MapListener?

  private var observer: NSObjectProtocol?

  private let services: MapServices

  init(presenter: MapPresentable, services: MapServices) {
    self.services = services
    super.init(presenter: presenter)
  }

  override func didBecomeActive() {
    super.didBecomeActive()

    presenter.authorizationStatus = services.locationService.authorizationStatus
    observer = services.locationService.addObserverForStatus { [weak self] authorizationStatus in
      self?.presenter.authorizationStatus = authorizationStatus
    }

    services.buildingsService.loadBuildings { [weak self] buildings, error in
      DispatchQueue.main.async {
        if let error = error {
          self?.listener?.mapDidError(error)
        } else {
          self?.presenter.buildings = buildings
        }
      }
    }
  }

  override func willResignActive() {
    super.willResignActive()

    if let observer = observer {
      services.locationService.removeObserver(observer)
    }
  }
}

extension MapInteractor: MapPresentableListener {
  func requestLocationAuthorization() {
    if let action = services.locationService.authorizationStatus.action {
      presenter.showAction(action)
    } else if services.locationService.authorizationStatus == .notDetermined {
      services.locationService.requestAuthorization()
    }
  }

  func openLocationSettings() {
    if let url = URL(string: UIApplication.openSettingsURLString) {
      services.openService.open(url, completion: nil)
    }
  }
}
