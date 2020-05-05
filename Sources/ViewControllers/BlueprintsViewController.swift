import UIKit

protocol BlueprintsViewControllerDelegate: AnyObject {
    func blueprintsViewControllerDidTapDismiss(_ blueprintsViewController: BlueprintsViewController)
    func blueprintsViewControllerDidSelectBlueprint(_ blueprintsViewController: BlueprintsViewController)
}

protocol BlueprintsViewControllerFullscreenDelegate: AnyObject {
    func blueprintsViewControllerDidTapFullscreen(_ blueprintViewController: BlueprintsViewController)
}

final class BlueprintsViewController: UIPageViewController {
    weak var blueprintsDelegate: BlueprintsViewControllerDelegate?

    weak var fullscreenDelegate: BlueprintsViewControllerFullscreenDelegate? {
        didSet { didChangeFullscreenDelegate() }
    }

    convenience init() {
        self.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [.interPageSpacing: 20])
    }

    var building: Building? {
        didSet { didChangeBuilding() }
    }

    private var blueprints: [Blueprint] {
        building?.blueprints ?? []
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
        dataSource = self

        navigationItem.rightBarButtonItem = makeDismissButton()

        let tapAction = #selector(didTapFullscreen)
        let tapRecognizer = UITapGestureRecognizer(target: self, action: tapAction)
        view.addGestureRecognizer(tapRecognizer)
        view.backgroundColor = .fos_systemBackground
    }

    private func didChangeBuilding() {
        setViewControllers([makeInitialViewController()], direction: .forward, animated: false)
        didChangeChildViewController()
    }

    private func didChangeFullscreenDelegate() {
        navigationItem.leftBarButtonItem = fullscreenDelegate == nil ? nil : makeFullscreenButton()
    }

    @objc private func didTapDismiss() {
        blueprintsDelegate?.blueprintsViewControllerDidTapDismiss(self)
    }

    @objc private func didTapFullscreen() {
        if !blueprints.isEmpty {
            fullscreenDelegate?.blueprintsViewControllerDidTapFullscreen(self)
        }
    }

    private func makeInitialViewController() -> UIViewController {
        if blueprints.isEmpty {
            return makeEmptyViewController()
        } else {
            return makeBlueprintViewController(at: 0)
        }
    }

    private func makeDismissButton() -> UIBarButtonItem {
        let dismissImageName = "xmark"
        let dismissAction = #selector(didTapDismiss)
        return makeBarButtonItem(forAction: dismissAction, withImageNamed: dismissImageName)
    }

    private func makeFullscreenButton() -> UIBarButtonItem {
        let fullscreenAction = #selector(didTapFullscreen)
        let fullscreenImageName = "arrow.up.left.and.arrow.down.right"
        return makeBarButtonItem(forAction: fullscreenAction, withImageNamed: fullscreenImageName)
    }

    private func makeBarButtonItem(forAction action: Selector, withImageNamed imageName: String) -> UIBarButtonItem {
        let image: UIImage?
        if #available(iOS 13.0, *) {
            image = UIImage(systemName: imageName)
        } else {
            image = UIImage(named: imageName)
        }
        return UIBarButtonItem(image: image, style: .plain, target: self, action: action)
    }
}

extension BlueprintsViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = viewController.fos_index else { return nil }

        let indexBefore = index - 1
        if blueprints.indices.contains(indexBefore) {
            return makeBlueprintViewController(at: indexBefore)
        } else {
            return nil
        }
    }

    func pageViewController(_: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = viewController.fos_index else { return nil }

        let indexAfter = index + 1
        if blueprints.indices.contains(indexAfter) {
            return makeBlueprintViewController(at: indexAfter)
        } else {
            return nil
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating _: Bool, previousViewControllers _: [UIViewController], transitionCompleted _: Bool) {
        didChangeChildViewController()
    }

    private func didChangeChildViewController() {
        if let blueprintViewController = viewControllers?.first as? BlueprintViewController, let blueprint = blueprintViewController.blueprint {
            title = blueprint.title
        } else {
            title = nil
        }
    }

    private func makeBlueprintViewController(at index: Int) -> BlueprintViewController {
        let blueprintViewController: BlueprintViewController = fullscreenDelegate == nil
            ? FullscreenBlueprintViewController()
            : EmbeddedBlueprintViewController()
        blueprintViewController.blueprint = blueprints[index]
        blueprintViewController.fos_index = index
        return blueprintViewController
    }

    private func makeEmptyViewController() -> BlueprintsEmptyViewController {
        BlueprintsEmptyViewController()
    }
}

private protocol BlueprintViewController: UIViewController {
    var blueprint: Blueprint? { get set }
}

extension EmbeddedBlueprintViewController: BlueprintViewController {}

extension FullscreenBlueprintViewController: BlueprintViewController {}

private extension UIViewController {
    private static var indexKey = 0

    var fos_index: Int? {
        get { objc_getAssociatedObject(self, &UIViewController.indexKey) as? Int }
        set { objc_setAssociatedObject(self, &UIViewController.indexKey, newValue as Int?, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
    }
}
