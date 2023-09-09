import CoreLocation
import UIKit

final class MapController: MapContainerViewController {
  typealias Dependencies = HasBuildingsService & HasOpenService

  var didError: ((MapController, Error) -> Void)?

  private weak var mapViewController: MapViewController?
  private weak var embeddedBlueprintsViewController: BlueprintsViewController?
  private weak var fullscreenBlueprintsViewController: BlueprintsViewController?

  private var transition: FullscreenBlueprintsDismissalTransition?
  private var observer: NSObjectProtocol?

  private let notificationCenter = NotificationCenter.default
  private let locationManager = CLLocationManager()

  private let dependencies: Dependencies

  init(dependencies: Dependencies) {
    self.dependencies = dependencies
    super.init(nibName: nil, bundle: nil)

    observer = notificationCenter.addObserver(forName: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
      self?.didChangeVoiceOverStatus()
    }
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    if let observer = observer {
      notificationCenter.removeObserver(observer)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    containerDelegate = self

    let blueprintsViewController = makeEmbeddedBlueprintsViewController()
    let blueprintsNavigationController = UINavigationController(rootViewController: blueprintsViewController)

    masterViewController = makeMapViewController()
    detailViewController = blueprintsNavigationController

    locationManager.delegate = self

    dependencies.buildingsService.loadBuildings { buildings, error in
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }

        if let error = error {
          self.didError?(self, error)
        } else {
          self.mapViewController?.buildings = buildings
        }
      }
    }
  }

  private var authorizationStatus: CLAuthorizationStatus {
    #if targetEnvironment(macCatalyst)
    return .denied
    #else
    return locationManager.authorizationStatus
    #endif
  }

  private func didChangeVoiceOverStatus() {
    if isViewLoaded, UIAccessibility.isVoiceOverRunning {
      mapViewController?.deselectSelectedAnnotation()
      mapViewController?.resetCamera(animated: true)
    }
  }

  private func didTapLocationSettings() {
    if let url = URL(string: UIApplication.openSettingsURLString) {
      dependencies.openService.open(url, completion: nil)
    }
  }
}

extension MapController: MapContainerViewControllerDelegate {
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

extension MapController: MapViewControllerDelegate {
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

  func mapViewControllerDidTapLocation(_ mapViewController: MapViewController) {
    if let action = authorizationStatus.action {
      let actionViewController = makeActionViewController(for: action)
      mapViewController.present(actionViewController, animated: true)
    } else if authorizationStatus == .notDetermined {
      locationManager.requestWhenInUseAuthorization()
    }
  }

  func mapViewControllerDidTapReset(_ mapViewController: MapViewController) {
    mapViewController.deselectSelectedAnnotation()
    mapViewController.resetCamera(animated: true)
  }
}

extension MapController: BlueprintsViewControllerDelegate {
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

extension MapController: CLLocationManagerDelegate {
  func locationManager(_: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    mapViewController?.setAuthorizationStatus(status)
  }
}

private extension MapController {
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

private extension CLAuthorizationStatus {
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

private extension CLAuthorizationStatus.Action {
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
