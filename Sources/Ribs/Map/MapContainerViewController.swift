import CoreLocation
import UIKit

protocol MapPresentableListener: AnyObject {
  func requestLocationAuthorization()
  func openLocationSettings()
}

class MapContainerViewController: ContainerViewController {
  weak var listener: MapPresentableListener?

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

  private let notificationCenter: NotificationCenter = .default

  deinit {
    if let observer = observer {
      notificationCenter.removeObserver(observer)
    }
  }
}

extension MapContainerViewController {
  override func viewDidLoad() {
    super.viewDidLoad()

    containerDelegate = self

    let embeddedBlueprintsViewController = BlueprintsViewController(style: .embedded)
    let embeddedBlueprintsNavigationController = UINavigationController(rootViewController: embeddedBlueprintsViewController)
    embeddedBlueprintsViewController.blueprintsDelegate = self
    self.embeddedBlueprintsViewController = embeddedBlueprintsViewController

    let mapViewController = MapViewController()
    mapViewController.delegate = self
    mapViewController.buildings = buildings
    mapViewController.setAuthorizationStatus(authorizationStatus)
    self.mapViewController = mapViewController

    masterViewController = mapViewController
    detailViewController = embeddedBlueprintsNavigationController

    observer = notificationCenter.addObserver(forName: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
      self?.didChangeVoiceOverStatus()
    }
  }
}

extension MapContainerViewController: ContainerViewControllerDelegate {
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

  func containerViewController(_: ContainerViewController, scrollDirectionFor _: UIViewController) -> ContainerViewController.ScrollDirection {
    switch preferredLayout {
    case .phonePortrait:
      return .vertical
    case .pad, .phoneLandscape:
      return .horizontal
    }
  }

  func containerViewController(_: ContainerViewController, rectFor _: UIViewController) -> CGRect {
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

  func containerViewController(_: ContainerViewController, didHide _: UIViewController) {
    mapViewController?.deselectSelectedAnnotation()
  }
}

extension MapContainerViewController: MapViewControllerDelegate {
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
    listener?.requestLocationAuthorization()
  }

  func mapViewControllerDidTapReset(_ mapViewController: MapViewController) {
    mapViewController.deselectSelectedAnnotation()
    mapViewController.resetCamera(animated: true)
  }
}

extension MapContainerViewController: BlueprintsViewControllerDelegate {
  func blueprintsViewControllerDidTapDismiss(_ blueprintsViewController: BlueprintsViewController) {
    if blueprintsViewController == embeddedBlueprintsViewController {
      mapViewController?.deselectSelectedAnnotation()
    } else if blueprintsViewController == fullscreenBlueprintsViewController {
      blueprintsViewController.dismiss(animated: true)
    }
  }

  func blueprintsViewController(_ presentingViewController: BlueprintsViewController, didSelect blueprint: Blueprint) {
    guard let building = presentingViewController.building else { return }

    let blueprintsViewController = BlueprintsViewController(style: .fullscreen)
    blueprintsViewController.building = building
    blueprintsViewController.blueprintsDelegate = self
    blueprintsViewController.setVisibleBlueprint(blueprint, animated: false)
    fullscreenBlueprintsViewController = blueprintsViewController

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

extension MapContainerViewController: MapPresentable {
  func showAction(_ action: CLAuthorizationStatus.Action) {
    let dismissTitle = L10n.Location.dismiss
    let dismissAction = UIAlertAction(title: dismissTitle, style: .cancel)

    let confirmTitle = L10n.Location.confirm
    let confirmAction = UIAlertAction(title: confirmTitle, style: .default) { [weak self] _ in
      self?.listener?.openLocationSettings()
    }

    let actionViewController = UIAlertController(title: action.title, message: action.message, preferredStyle: .alert)
    actionViewController.addAction(dismissAction)
    actionViewController.addAction(confirmAction)
    mapViewController?.present(actionViewController, animated: true)
  }
}

private extension MapContainerViewController {
  func didChangeVoiceOverStatus() {
    if isViewLoaded, UIAccessibility.isVoiceOverRunning {
      mapViewController?.deselectSelectedAnnotation()
      mapViewController?.resetCamera(animated: true)
    }
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
