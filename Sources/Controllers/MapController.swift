import CoreLocation
import UIKit

protocol MapControllerDelegate: AnyObject {
    func mapController(_ mapController: MapController, didError error: Error)
}

final class MapController: MapContainerViewController {
    weak var delegate: MapControllerDelegate?

    private weak var mapViewController: MapViewController?
    private weak var embeddedBlueprintsViewController: BlueprintsViewController?
    private weak var fullscreenBlueprintsViewController: BlueprintsViewController?
    private weak var fullscreenBlueprintsNavigationController: UINavigationController?

    private var transition: FullscreenBlueprintsDismissalTransition?
    private var observer: NSObjectProtocol?

    private let locationManager = CLLocationManager()
    private let services: Services

    init(services: Services) {
        self.services = services
        super.init(nibName: nil, bundle: nil)

        observer = notificationCenter.addObserver(forName: UIAccessibility.fos_voiceOverStatusDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            self?.didChangeVoiceOverStatus()
        }
    }

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

        services.buildingsService.loadBuildings { buildings, error in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                if let error = error {
                    self.delegate?.mapController(self, didError: error)
                } else {
                    self.mapViewController?.buildings = buildings
                }
            }
        }
    }

    private var notificationCenter: NotificationCenter {
        .default
    }

    private var authorizationStatus: CLAuthorizationStatus {
        CLLocationManager.authorizationStatus()
    }

    private func didChangeVoiceOverStatus() {
        if isViewLoaded, UIAccessibility.isVoiceOverRunning {
            mapViewController?.deselectSelectedAnnotation()
            mapViewController?.resetCamera(animated: true)
        }
    }

    private func didTapLocationSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

extension MapController: MapContainerViewControllerDelegate {
    private enum Layout {
        case pad, phonePortrait, phoneLandscape
    }

    private var preferredLayout: Layout {
        if traitCollection.userInterfaceIdiom == .pad {
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
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse, .denied, .restricted:
            let settingsViewController = makeLocationSettingsViewController(for: authorizationStatus)
            mapViewController.present(settingsViewController, animated: true)
        @unknown default:
            break
        }
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
        fullscreenBlueprintsNavigationController = blueprintsNavigationController

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

    func makeLocationSettingsViewController(for status: CLAuthorizationStatus) -> UIAlertController {
        let dismissTitle = NSLocalizedString("location.dismiss", comment: "")
        let dismissAction = UIAlertAction(title: dismissTitle, style: .cancel)

        let confirmTitle = NSLocalizedString("location.confirm", comment: "")
        let confirmAction = UIAlertAction(title: confirmTitle, style: .default) { [weak self] _ in
            self?.didTapLocationSettings()
        }

        let alertTitle = NSLocalizedString("location.title", comment: "")
        let alertController = UIAlertController(title: alertTitle, message: status.settingsMessage, preferredStyle: .alert)
        alertController.addAction(dismissAction)
        alertController.addAction(confirmAction)
        return alertController
    }
}

private extension CLAuthorizationStatus {
    var settingsMessage: String? {
        switch self {
        case .authorizedAlways, .authorizedWhenInUse:
            return NSLocalizedString("location.message.disable", comment: "")
        case .denied, .restricted:
            return NSLocalizedString("location.message.enable", comment: "")
        case .notDetermined:
            return nil
        @unknown default:
            return nil
        }
    }
}
