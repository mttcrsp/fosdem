import Combine
import CoreLocation
import UIKit

final class MapMainViewController: MapContainerViewController {
  var didError: ((MapMainViewController, Error) -> Void)?

  private weak var embeddedBlueprintsViewController: BlueprintsViewController?
  private weak var fullscreenBlueprintsViewController: BlueprintsViewController?
  private weak var mapViewController: MapViewController?
  private var cancellables: [AnyCancellable] = []
  private var observer: NSObjectProtocol?
  private var transition: FullscreenBlueprintsDismissalTransition?
  private let notificationCenter = NotificationCenter.default
  private let viewModel: MapViewModel

  init(viewModel: MapViewModel) {
    self.viewModel = viewModel
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
    if let observer {
      notificationCenter.removeObserver(observer)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    containerDelegate = self

    let blueprintsViewController = BlueprintsViewController(style: .embedded)
    let blueprintsNavigationController = UINavigationController(rootViewController: blueprintsViewController)
    blueprintsViewController.blueprintsDelegate = self
    embeddedBlueprintsViewController = blueprintsViewController

    let mapViewController = MapViewController()
    mapViewController.delegate = self
    self.mapViewController = mapViewController

    masterViewController = mapViewController
    detailViewController = blueprintsNavigationController

    viewModel.$authorizationStatus
      .receive(on: DispatchQueue.main)
      .sink { status in
        mapViewController.setAuthorizationStatus(status)
      }
      .store(in: &cancellables)

    viewModel.$buildings
      .receive(on: DispatchQueue.main)
      .sink { buildings in
        mapViewController.buildings = buildings
      }
      .store(in: &cancellables)

    viewModel.didFail
      .sink { [weak self] error in
        guard let self else { return }
        didError?(self, error)
      }
      .store(in: &cancellables)

    viewModel.didLoad()
  }

  private func didChangeVoiceOverStatus() {
    if isViewLoaded, UIAccessibility.isVoiceOverRunning {
      mapViewController?.deselectSelectedAnnotation()
      mapViewController?.resetCamera(animated: true)
    }
  }
}

extension MapMainViewController: MapContainerViewControllerDelegate {
  private enum Layout {
    case pad, phonePortrait, phoneLandscape
  }

  private var preferredLayout: Layout {
    if traitCollection.fos_hasRegularSizeClasses {
      .pad
    } else if view.bounds.height > view.bounds.width {
      .phonePortrait
    } else {
      .phoneLandscape
    }
  }

  func containerViewController(_: MapContainerViewController, scrollDirectionFor _: UIViewController) -> MapContainerViewController.ScrollDirection {
    switch preferredLayout {
    case .phonePortrait: .vertical
    case .pad, .phoneLandscape: .horizontal
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

extension MapMainViewController: MapViewControllerDelegate {
  func mapViewController(_ mapViewController: MapViewController, didSelect building: Building) {
    embeddedBlueprintsViewController?.building = building
    setDetailViewControllerVisible(true, animated: true)

    let detailSize = detailViewController?.view.frame.size ?? .zero

    var center = mapViewController.convertToMapPoint(building.coordinate)
    switch preferredLayout {
    case .pad: break
    case .phonePortrait: center.y += detailSize.height / 2
    case .phoneLandscape: center.x -= detailSize.width / 2
    }

    let centerCoordinates = mapViewController.convertToMapCoordinate(center)
    mapViewController.setCenter(centerCoordinates, animated: true)
  }

  func mapViewControllerDidDeselectBuilding(_: MapViewController) {
    setDetailViewControllerVisible(false, animated: true)
  }

  func mapViewControllerDidTapLocation(_ mapViewController: MapViewController) {
    if let action = viewModel.authorizationStatus.action {
      let dismissTitle = L10n.Location.dismiss
      let dismissAction = UIAlertAction(title: dismissTitle, style: .cancel)

      let confirmTitle = L10n.Location.confirm
      let confirmAction = UIAlertAction(title: confirmTitle, style: .default) { [weak self] _ in
        self?.viewModel.didSelectLocationSettings()
      }

      let alertController = UIAlertController(title: action.title, message: action.message, preferredStyle: .alert)
      alertController.addAction(dismissAction)
      alertController.addAction(confirmAction)
      mapViewController.present(alertController, animated: true)
    } else if viewModel.authorizationStatus == .notDetermined {
      viewModel.didSelectLocation()
    }
  }

  func mapViewControllerDidTapReset(_ mapViewController: MapViewController) {
    mapViewController.deselectSelectedAnnotation()
    mapViewController.resetCamera(animated: true)
  }
}

extension MapMainViewController: BlueprintsViewControllerDelegate {
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

private extension CLAuthorizationStatus {
  enum Action {
    case enable, disable
  }

  var action: Action? {
    switch self {
    case .authorizedAlways, .authorizedWhenInUse: .disable
    case .denied, .restricted: .enable
    case .notDetermined: nil
    @unknown default: nil
    }
  }
}

private extension CLAuthorizationStatus.Action {
  var title: String {
    switch self {
    case .enable: L10n.Location.Title.enable
    case .disable: L10n.Location.Title.disable
    }
  }

  var message: String {
    switch self {
    case .enable: L10n.Location.Message.enable
    case .disable: L10n.Location.Message.disable
    }
  }
}
