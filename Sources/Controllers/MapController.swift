import UIKit

final class MapController: UIViewController {
    private weak var mapViewController: MapViewController?
    private weak var embeddedBlueprintsViewController: BlueprintsViewController?
    private weak var blueprintsNavigationController: UINavigationController?
    private weak var fullscreenBlueprintsViewController: BlueprintsViewController?
    private weak var fullscreenBlueprintsNavigationController: UINavigationController?

    private var transition: FullscreenBlueprintsDismissalTransition?

    private let services: Services

    init(services: Services) {
        self.services = services
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
                self?.mapViewController?.buildings = buildings
                if error != nil {
                    self?.mapViewController?.present(ErrorController(), animated: true)
                }
            }
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
