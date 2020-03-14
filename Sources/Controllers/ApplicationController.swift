import UIKit

final class ApplicationController: UITabBarController {
    private let services: Services

    init(services: Services) {
        self.services = services
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var previouslySelectedViewController: String? {
        get { UserDefaults.standard.selectedViewController }
        set { UserDefaults.standard.selectedViewController = newValue }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self

        var viewControllers: [UIViewController] = []
        viewControllers.append(makeTracksController())
        viewControllers.append(makePlanController())
        viewControllers.append(makeMoreController())
        setViewControllers(viewControllers, animated: false)

        for (index, viewController) in viewControllers.enumerated() where String(describing: type(of: viewController)) == previouslySelectedViewController {
            selectedIndex = index
        }
    }
}

private extension ApplicationController {
    func makePlanController() -> PlanController {
        let planController = PlanController(services: services)
        planController.title = NSLocalizedString("plan.title", comment: "")
        return planController
    }

    func makeTracksController() -> TracksController {
        let tracksController = TracksController(services: services)
        tracksController.title = NSLocalizedString("tracks.title", comment: "")
        return tracksController
    }

    func makeMoreController() -> MoreController {
        let moreController = MoreController(services: services)
        moreController.title = NSLocalizedString("more.title", comment: "")
        return moreController
    }
}

extension ApplicationController: UITabBarControllerDelegate {
    func tabBarController(_: UITabBarController, didSelect viewController: UIViewController) {
        previouslySelectedViewController = String(describing: type(of: viewController))
    }
}

private extension UserDefaults {
    var selectedViewController: String? {
        get { string(forKey: .selectedViewControllerKey) }
        set { set(newValue, forKey: .selectedViewControllerKey) }
    }
}

private extension String {
    static var selectedViewControllerKey: String { #function }
}
