import CoreLocation
import RIBs
import UIKit

protocol HasLocationService {
  var locationService: LocationServiceProtocol { get }
}

protocol LocationServiceProtocol {
  var authorizationStatus: CLAuthorizationStatus { get }
  func requestAuthorization()
  func addObserverForStatus(_ handler: @escaping (CLAuthorizationStatus) -> Void) -> NSObjectProtocol
  func removeObserver(_ observer: NSObjectProtocol)
}

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

extension LocationService: LocationServiceProtocol {}

private extension Notification.Name {
  static var authorizationStatusDidChange: Notification.Name { Notification.Name(#function) }
}

typealias MapDependency = HasBuildingsService
  & HasLocationService
  & HasNotificationCenter
  & HasOpenService

private let notificationCenter = NotificationCenter.default
private let locationManager = CLLocationManager()

protocol MapBuildable: Buildable {
  func build(with listener: MapListener) -> LaunchRouting
}

class MapBuilder: Builder<MapDependency>, MapBuildable {
  func build(with listener: MapListener) -> LaunchRouting {
    let viewController = _MapController()
    let interactor = MapInteractor(dependency: dependency, presenter: viewController)
    let router = MapRouter(interactor: interactor, viewController: viewController)
    interactor.listener = listener
    return router
  }
}

class MapRouter: LaunchRouter<MapInteractable, MapViewControllable> {}

protocol MapInteractable: Interactable {}

protocol MapListener: AnyObject {
  func mapDidError(_ error: Error)
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
    observer = dependency.locationService.addObserverForStatus { authorizationStatus in
      self.presenter.authorizationStatus = authorizationStatus
    }

    dependency.buildingsService.loadBuildings { buildings, error in
      DispatchQueue.main.async { [weak self] in
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

extension MapInteractor: MapInteractable {}

extension MapInteractor: _MapControllerListener {
  func didSelectLocation() {
    if let action = dependency.locationService.authorizationStatus.action {
      presenter.showAction(action)
    } else if dependency.locationService.authorizationStatus == .notDetermined {
      dependency.locationService.requestAuthorization()
    }
  }

  func didSelectLocationSettings() {
    if let url = URL(string: UIApplication.openSettingsURLString) {
      dependency.openService.open(url, completion: nil)
    }
  }
}

protocol MapViewControllable: ViewControllable {}

protocol MapPresentable: Presentable {
  var authorizationStatus: CLAuthorizationStatus { get set }
  var buildings: [Building] { get set }
  func showAction(_ action: CLAuthorizationStatus.Action)
}

protocol _MapControllerListener: AnyObject {
  func didSelectLocation()
  func didSelectLocationSettings()
}

class _MapController: MapContainerViewController {
  weak var listener: _MapControllerListener?

  var authorizationStatus: CLAuthorizationStatus = .notDetermined {
    didSet { mapViewController?.setAuthorizationStatus(authorizationStatus) }
  }

  var buildings: [Building] = [] {
    didSet { mapViewController?.buildings = buildings }
  }

  private weak var mapViewController: MapViewController?
  private weak var embeddedBlueprintsViewController: BlueprintsViewController?
  private weak var fullscreenBlueprintsViewController: BlueprintsViewController?

  private var transition: FullscreenBlueprintsDismissalTransition?
  private var observer: NSObjectProtocol?

  deinit {
    if let observer = observer {
      notificationCenter.removeObserver(observer)
    }
  }

  func showAction(_ action: CLAuthorizationStatus.Action) {
    let actionViewController = makeActionViewController(for: action)
    mapViewController?.present(actionViewController, animated: true)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    containerDelegate = self

    let blueprintsViewController = makeEmbeddedBlueprintsViewController()
    let blueprintsNavigationController = UINavigationController(rootViewController: blueprintsViewController)

    masterViewController = makeMapViewController()
    detailViewController = blueprintsNavigationController

    observer = notificationCenter.addObserver(forName: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
      self?.didChangeVoiceOverStatus()
    }
  }

  private func didChangeVoiceOverStatus() {
    if isViewLoaded, UIAccessibility.isVoiceOverRunning {
      mapViewController?.deselectSelectedAnnotation()
      mapViewController?.resetCamera(animated: true)
    }
  }

  private func didTapLocationSettings() {
    listener?.didSelectLocationSettings()
  }
}

extension _MapController: MapContainerViewControllerDelegate {
  private enum Layout {
    case pad, phonePortrait, phoneLandscape
  }

  private var preferredLayout: Layout {
    if traitCollection.fos_hasRegularSizeClasses {
      return .pad
    } else if view.bounds.height > view.bounds.width {
      return .phonePortrait
    } else {
      return .phoneLandscape
    }
  }

  func containerViewController(_: MapContainerViewController, scrollDirectionFor _: UIViewController) -> MapContainerViewController.ScrollDirection {
    switch preferredLayout {
    case .phonePortrait:
      return .vertical
    case .pad, .phoneLandscape:
      return .horizontal
    }
  }

  func containerViewController(_: MapContainerViewController, rectFor _: UIViewController) -> CGRect {
    var rect = CGRect()
    switch preferredLayout {
    case .pad:
      rect.size = CGSize(width: 320, height: 320)
      rect.origin.x = view.layoutMargins.left
      rect.origin.y = view.layoutMargins.left + view.layoutMargins.top
    case .phonePortrait:
      rect.size.width = view.bounds.width - view.layoutMargins.left - view.layoutMargins.right
      rect.size.height = 200
      rect.origin.x = view.layoutMargins.left
      rect.origin.y = view.bounds.height - view.layoutMargins.bottom - rect.height - 32
    case .phoneLandscape:
      rect.size.width = 300
      rect.size.height = view.bounds.height - view.layoutMargins.bottom - 48
      rect.origin.x = view.layoutMargins.left
      rect.origin.y = 16
    }
    return rect
  }

  func containerViewController(_: MapContainerViewController, didHide _: UIViewController) {
    mapViewController?.deselectSelectedAnnotation()
  }
}

extension _MapController: MapViewControllerDelegate {
  func mapViewController(_ mapViewController: MapViewController, didSelect building: Building) {
    embeddedBlueprintsViewController?.building = building
    setDetailViewControllerVisible(true, animated: true)

    let detailSize = detailViewController?.view.frame.size ?? .zero

    var center = mapViewController.convertToMapPoint(building.coordinate)
    switch preferredLayout {
    case .pad:
      break
    case .phonePortrait:
      center.y += detailSize.height / 2
    case .phoneLandscape:
      center.x -= detailSize.width / 2
    }

    let centerCoordinates = mapViewController.convertToMapCoordinate(center)
    mapViewController.setCenter(centerCoordinates, animated: true)
  }

  func mapViewControllerDidDeselectBuilding(_: MapViewController) {
    setDetailViewControllerVisible(false, animated: true)
  }

  func mapViewControllerDidTapLocation(_: MapViewController) {
    listener?.didSelectLocation()
  }

  func mapViewControllerDidTapReset(_ mapViewController: MapViewController) {
    mapViewController.deselectSelectedAnnotation()
    mapViewController.resetCamera(animated: true)
  }
}

extension _MapController: BlueprintsViewControllerDelegate {
  func blueprintsViewControllerDidTapDismiss(_ blueprintsViewController: BlueprintsViewController) {
    if blueprintsViewController == embeddedBlueprintsViewController {
      mapViewController?.deselectSelectedAnnotation()
    } else if blueprintsViewController == fullscreenBlueprintsViewController {
      blueprintsViewController.dismiss(animated: true)
    }
  }

  func blueprintsViewController(_ presentingViewController: BlueprintsViewController, didSelect blueprint: Blueprint) {
    guard let building = presentingViewController.building else { return }

    let blueprintsViewController = makeFullscreeBlueprintsViewController(for: building, showing: blueprint)
    let blueprintsNavigationController = UINavigationController(rootViewController: blueprintsViewController)
    blueprintsNavigationController.modalPresentationStyle = .overFullScreen

    let navigationBar = blueprintsNavigationController.navigationBar
    navigationBar.setBackgroundImage(UIImage(), for: .default)
    navigationBar.shadowImage = UIImage()

    let transition = FullscreenBlueprintsDismissalTransition(dismissedViewController: blueprintsNavigationController)
    blueprintsNavigationController.view.addGestureRecognizer(transition.panRecognizer)
    blueprintsNavigationController.transitioningDelegate = transition
    self.transition = transition

    presentingViewController.present(blueprintsNavigationController, animated: true)

    blueprintsNavigationController.view.alpha = 0
    blueprintsNavigationController.transitionCoordinator?.animate(alongsideTransition: { [weak blueprintsNavigationController] _ in
      blueprintsNavigationController?.view.alpha = 1
    }, completion: { [weak blueprintsNavigationController] _ in
      blueprintsNavigationController?.view.alpha = 1
    })
  }
}

extension _MapController: MapViewControllable {}

extension _MapController: MapPresentable {}

private extension _MapController {
  func makeMapViewController() -> MapViewController {
    let mapViewController = MapViewController()
    mapViewController.delegate = self
    mapViewController.setAuthorizationStatus(authorizationStatus)
    self.mapViewController = mapViewController
    return mapViewController
  }

  func makeEmbeddedBlueprintsViewController() -> BlueprintsViewController {
    let blueprintsViewController = BlueprintsViewController(style: .embedded)
    blueprintsViewController.blueprintsDelegate = self
    embeddedBlueprintsViewController = blueprintsViewController
    return blueprintsViewController
  }

  func makeFullscreeBlueprintsViewController(for building: Building, showing blueprint: Blueprint) -> BlueprintsViewController {
    let blueprintsViewController = BlueprintsViewController(style: .fullscreen)
    blueprintsViewController.building = building
    blueprintsViewController.blueprintsDelegate = self
    blueprintsViewController.setVisibleBlueprint(blueprint, animated: false)
    fullscreenBlueprintsViewController = blueprintsViewController
    return blueprintsViewController
  }

  func makeActionViewController(for action: CLAuthorizationStatus.Action) -> UIAlertController {
    let dismissTitle = L10n.Location.dismiss
    let dismissAction = UIAlertAction(title: dismissTitle, style: .cancel)

    let confirmTitle = L10n.Location.confirm
    let confirmAction = UIAlertAction(title: confirmTitle, style: .default) { [weak self] _ in
      self?.didTapLocationSettings()
    }

    let alertController = UIAlertController(title: action.title, message: action.message, preferredStyle: .alert)
    alertController.addAction(dismissAction)
    alertController.addAction(confirmAction)
    return alertController
  }
}

extension CLAuthorizationStatus {
  enum Action {
    case enable, disable
  }

  var action: Action? {
    switch self {
    case .authorizedAlways, .authorizedWhenInUse:
      return .disable
    case .denied, .restricted:
      return .enable
    case .notDetermined:
      return nil
    @unknown default:
      return nil
    }
  }
}

extension CLAuthorizationStatus.Action {
  var title: String {
    switch self {
    case .enable:
      return L10n.Location.Title.enable
    case .disable:
      return L10n.Location.Title.disable
    }
  }

  var message: String {
    switch self {
    case .enable:
      return L10n.Location.Message.enable
    case .disable:
      return L10n.Location.Message.disable
    }
  }
}
