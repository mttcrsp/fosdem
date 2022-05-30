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

  private let dependency: MapDependency

  init(dependency: MapDependency, presenter: MapPresentable) {
    self.dependency = dependency
    super.init(presenter: presenter)
  }

  override func didBecomeActive() {
    super.didBecomeActive()

    presenter.authorizationStatus = dependency.locationService.authorizationStatus
    observer = dependency.locationService.addObserverForStatus { [weak self] authorizationStatus in
      self?.presenter.authorizationStatus = authorizationStatus
    }

    dependency.buildingsService.loadBuildings { [weak self] buildings, error in
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
      dependency.locationService.removeObserver(observer)
    }
  }
}

extension MapInteractor: MapPresentableListener {
  func requestLocationAuthorization() {
    if let action = dependency.locationService.authorizationStatus.action {
      presenter.showAction(action)
    } else if dependency.locationService.authorizationStatus == .notDetermined {
      dependency.locationService.requestAuthorization()
    }
  }

  func openLocationSettings() {
    if let url = URL(string: UIApplication.openSettingsURLString) {
      dependency.openService.open(url, completion: nil)
    }
  }
}
