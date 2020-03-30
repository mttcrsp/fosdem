import UIKit

final class MapController: UIViewController {
    private weak var mapViewController: MapViewController?
    private weak var blueprintsViewController: BlueprintsViewController?
    private weak var blueprintsNavigationController: UINavigationController?

    override func viewDidLoad() {
        super.viewDidLoad()

        let mapViewController = makeMapViewController()
        addChild(mapViewController)
        view.addSubview(mapViewController.view)
        mapViewController.didMove(toParent: self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mapViewController?.view.frame = view.bounds

        guard let blueprintsView = blueprintsNavigationController?.view else { return }

        if view.bounds.width < view.bounds.height {
            blueprintsView.frame.size.width = view.bounds.width - view.layoutMargins.left - view.layoutMargins.right
            blueprintsView.frame.size.height = 200
            blueprintsView.frame.origin.x = view.layoutMargins.left
            blueprintsView.frame.origin.y = view.bounds.height - blueprintsView.bounds.height - 32
        } else {
            blueprintsView.frame.size.width = 300
            blueprintsView.frame.size.height = view.bounds.height - 48
            blueprintsView.frame.origin.x = view.layoutMargins.left
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
    func blueprintsViewControllerDidTapDismiss(_: BlueprintsViewController) {
        mapViewController?.deselectSelectedAnnotation()
    }

    func blueprintsViewControllerDidTapFullscreen(_: BlueprintsViewController) {
        mapViewController?.deselectSelectedAnnotation()
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
        blueprintsViewController.building = building
        blueprintsViewController.delegate = self
        self.blueprintsViewController = blueprintsViewController
        return blueprintsViewController
    }
}
