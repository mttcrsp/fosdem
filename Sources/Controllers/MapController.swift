import UIKit

final class MapController: UIViewController {
    private weak var mapViewController: MapViewController?
    private weak var blueprintsViewController: BlueprintsViewController?

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

        guard let blueprintsView = blueprintsViewController?.view else { return }

        blueprintsView.frame.size.width = view.bounds.width - view.layoutMargins.left - view.layoutMargins.right
        blueprintsView.frame.size.height = 200
        blueprintsView.frame.origin.x = view.layoutMargins.left
        blueprintsView.frame.origin.y = view.bounds.height - blueprintsView.bounds.height - 32
    }
}

extension MapController: MapViewControllerDelegate {
    func mapViewController(_: MapViewController, didSelect building: Building) {
        if let blueprintViewController = blueprintsViewController {
            blueprintViewController.building = building
            return
        }

        let blueprintViewController = makeBlueprintsViewController(for: building)
        addChild(blueprintViewController)

        let blueprintsView: UIView = blueprintViewController.view
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
            self.blueprintsViewController?.view.alpha = 1
        }
        animator.addCompletion { [weak self] _ in
            guard let self = self else { return }
            self.blueprintsViewController?.didMove(toParent: self)
        }
        animator.startAnimation()
    }

    func mapViewControllerDidDeselectBuilding(_: MapViewController) {
        blueprintsViewController?.willMove(toParent: nil)

        let animator = UIViewPropertyAnimator(duration: 0.3, dampingRatio: 0.8)
        animator.addAnimations { [weak self] in
            self?.blueprintsViewController?.view.alpha = 0
        }
        animator.addCompletion { [weak self] _ in
            self?.blueprintsViewController?.view.removeFromSuperview()
            self?.blueprintsViewController?.removeFromParent()
        }
        animator.startAnimation()
    }
}

extension MapController: BlueprintViewControllerDelegate {
    func blueprintViewControllerDidTapDismiss(_: BlueprintsViewController) {
        mapViewController?.deselectSelectedAnnotation()
    }

    func blueprintViewControllerDidTapFullscreen(_: BlueprintsViewController) {
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
        blueprintsViewController.building = building
        blueprintsViewController.delegate = self
        self.blueprintsViewController = blueprintsViewController
        return blueprintsViewController
    }
}
