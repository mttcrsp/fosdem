import UIKit

protocol MapControllerDelegate: AnyObject {
    func mapController(_ mapController: MapController, didError error: Error)
}

extension UIAccessibility {
    static var fos_voiceOverStatusDidChangeNotification: NSNotification.Name {
        if #available(iOS 11.0, *) {
            return UIAccessibility.voiceOverStatusDidChangeNotification
        } else {
            return NSNotification.Name(rawValue: UIAccessibilityVoiceOverStatusChanged)
        }
    }
}

final class MapController: UIViewController {
    weak var delegate: MapControllerDelegate?

    private weak var mapViewController: MapViewController?
    private weak var embeddedBlueprintsViewController: BlueprintsViewController?
    private weak var blueprintsNavigationController: UINavigationController?
    private weak var fullscreenBlueprintsViewController: BlueprintsViewController?
    private weak var fullscreenBlueprintsNavigationController: UINavigationController?

    private var transition: FullscreenBlueprintsDismissalTransition?
    private var observer: NSObjectProtocol?

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

        let mapViewController = makeMapViewController()
        addChild(mapViewController)
        view.addSubview(mapViewController.view)
        mapViewController.didMove(toParent: self)

        services.locationService.delegate = self
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

    private func didChangeVoiceOverStatus() {
        if isViewLoaded, UIAccessibility.isVoiceOverRunning {
            mapViewController?.deselectSelectedAnnotation()
            mapViewController?.resetCamera()
        }
    }
}

extension MapController: MapViewControllerDelegate {
    func mapViewController(_: MapViewController, didSelect building: Building) {
        if let blueprintsViewController = embeddedBlueprintsViewController {
            blueprintsViewController.building = building
            return
        }

        let blueprintsViewController = makeEmbeddedBlueprintsViewController(for: building)
        let blueprintsNavigationController = UINavigationController(rootViewController: blueprintsViewController)
        self.blueprintsNavigationController = blueprintsNavigationController
        mapViewController?.addBlueprintsViewController(blueprintsNavigationController)
    }

    func mapViewControllerDidDeselectBuilding(_: MapViewController) {
        mapViewController?.removeBlueprinsViewController()
    }

    func mapViewControllerDidTapLocation(_: MapViewController) {
        services.locationService.requestAuthorization()
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

extension MapController: LocationServiceDelegate {
    func locationServiceDidChangeStatus(_: LocationService) {
        mapViewController?.showsLocationButton = canRequestLocation
    }

    private var canRequestLocation: Bool {
        services.locationService.canRequestLocation
    }
}

private extension MapController {
    func makeMapViewController() -> MapViewController {
        let mapViewController = MapViewController()
        mapViewController.delegate = self
        mapViewController.showsLocationButton = canRequestLocation
        self.mapViewController = mapViewController
        return mapViewController
    }

    func makeEmbeddedBlueprintsViewController(for building: Building) -> BlueprintsViewController {
        let blueprintsViewController = BlueprintsViewController(style: .embedded)
        blueprintsViewController.building = building
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
}
