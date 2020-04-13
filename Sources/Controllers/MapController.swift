import UIKit

final class MapController: UIViewController {
    private weak var mapViewController: MapViewController?
    private weak var blueprintsViewController: BlueprintsViewController?
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

        services.buildingsService.loadBuildings { buildings, error in
            DispatchQueue.main.async { [weak self] in
                self?.mapViewController?.buildings = buildings
                if error != nil {
                    self?.mapViewController?.present(ErrorController(), animated: true)
                }
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let mapView = mapViewController?.view else { return }

        mapViewController?.view.frame = view.bounds

        guard let blueprintsView = blueprintsNavigationController?.view else { return }

        if view.bounds.width < view.bounds.height {
            blueprintsView.frame.size.width = mapView.bounds.width - mapView.layoutMargins.left - mapView.layoutMargins.right
            blueprintsView.frame.size.height = 200
            blueprintsView.frame.origin.x = mapView.layoutMargins.left
            blueprintsView.frame.origin.y = mapView.bounds.height - mapView.layoutMargins.bottom - blueprintsView.bounds.height - 32
        } else {
            blueprintsView.frame.size.width = 300
            blueprintsView.frame.size.height = mapView.bounds.height - mapView.layoutMargins.bottom - 48
            blueprintsView.frame.origin.x = mapView.layoutMargins.left
            blueprintsView.frame.origin.y = 16
        }
    }
}

extension MapController: MapViewControllerDelegate {
    func mapViewController(_: MapViewController, didSelect building: Building) {
        if let blueprintViewController = blueprintsViewController {
            blueprintViewController.building = building
            return
        }

        let blueprintsViewController = makeBlueprintsViewController(for: building)
        let blueprintsNavigationController = UINavigationController(rootViewController: blueprintsViewController)
        self.blueprintsNavigationController = blueprintsNavigationController

        addChild(blueprintsNavigationController)

        let blueprintsView: UIView = blueprintsNavigationController.view
        blueprintsView.backgroundColor = .fos_systemBackground
        blueprintsView.alpha = 0
        blueprintsView.layer.cornerRadius = 8
        blueprintsView.layer.shadowRadius = 8
        blueprintsView.layer.shadowOpacity = 0.2
        blueprintsView.layer.shadowOffset = .zero
        blueprintsView.layer.shadowColor = UIColor.black.cgColor
        view.addSubview(blueprintsView)

        let animator = UIViewPropertyAnimator(duration: 0.3, dampingRatio: 0.8)
        animator.addAnimations { [weak self] in
            guard let self = self else { return }
            self.blueprintsNavigationController?.view.alpha = 1
        }
        animator.addCompletion { [weak self] _ in
            guard let self = self else { return }
            self.blueprintsNavigationController?.didMove(toParent: self)
        }
        animator.startAnimation()
    }

    func mapViewControllerDidDeselectBuilding(_: MapViewController) {
        blueprintsNavigationController?.willMove(toParent: nil)

        let animator = UIViewPropertyAnimator(duration: 0.3, dampingRatio: 0.8)
        animator.addAnimations { [weak self] in
            self?.blueprintsNavigationController?.view.alpha = 0
        }
        animator.addCompletion { [weak self] _ in
            self?.blueprintsNavigationController?.view.removeFromSuperview()
            self?.blueprintsNavigationController?.removeFromParent()
        }
        animator.startAnimation()
    }
}

extension MapController: BlueprintsViewControllerDelegate {
    func blueprintsViewControllerDidTapDismiss(_ blueprintsViewController: BlueprintsViewController) {
        if blueprintsViewController == self.blueprintsViewController {
            mapViewController?.deselectSelectedAnnotation()
        } else if blueprintsViewController == fullscreenBlueprintsViewController {
            blueprintsViewController.dismiss(animated: true)
        }
    }

    func blueprintsViewControllerDidSelectBlueprint(_ blueprintsViewController: BlueprintsViewController) {
        if blueprintsViewController == self.blueprintsViewController {
            blueprintsViewControllerDidTapFullscreen(blueprintsViewController)
        }
    }
}

extension MapController: BlueprintsViewControllerFullscreenDelegate {
    func blueprintsViewControllerDidTapFullscreen(_ presentingViewController: BlueprintsViewController) {
        guard let building = presentingViewController.building else { return }

        let blueprintsViewController = makeFullscreenBlueprintsViewController(for: building)
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

private extension MapController {
    func makeMapViewController() -> MapViewController {
        let mapViewController = MapViewController()
        mapViewController.delegate = self
        self.mapViewController = mapViewController
        return mapViewController
    }

    func makeBlueprintsViewController(for building: Building) -> BlueprintsViewController {
        let blueprintsViewController = BlueprintsViewController()
        blueprintsViewController.extendedLayoutIncludesOpaqueBars = true
        blueprintsViewController.edgesForExtendedLayout = .bottom
        blueprintsViewController.fullscreenDelegate = self
        blueprintsViewController.building = building
        blueprintsViewController.delegate = self
        self.blueprintsViewController = blueprintsViewController
        return blueprintsViewController
    }

    func makeFullscreenBlueprintsViewController(for building: Building) -> BlueprintsViewController {
        let blueprintsViewController = BlueprintsViewController()
        blueprintsViewController.building = building
        blueprintsViewController.delegate = self
        fullscreenBlueprintsViewController = blueprintsViewController
        return blueprintsViewController
    }
}
