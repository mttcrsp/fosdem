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

  private let component: MapComponent

  init(presenter: MapPresentable, component: MapComponent) {
    self.component = component
    super.init(presenter: presenter)
  }

  override func didBecomeActive() {
    super.didBecomeActive()

    presenter.authorizationStatus = component.locationService.authorizationStatus
    observer = component.locationService.addObserverForStatus { [weak self] authorizationStatus in
      self?.presenter.authorizationStatus = authorizationStatus
    }

    component.buildingsService.loadBuildings { [weak self] buildings, error in
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
      component.locationService.removeObserver(observer)
    }
  }
}

extension MapInteractor: MapPresentableListener {
  func requestLocationAuthorization() {
    if let action = component.locationService.authorizationStatus.action {
      presenter.showAction(action)
    } else if component.locationService.authorizationStatus == .notDetermined {
      component.locationService.requestAuthorization()
    }
  }

  func openLocationSettings() {
    if let url = URL(string: UIApplication.openSettingsURLString) {
      component.openService.open(url, completion: nil)
    }
  }
}
