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
        viewControllers.append(makeHomeController())
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

        if #available(iOS 13.0, *) {
            planController.tabBarItem.image = UIImage(systemName: "calendar")
        } else {
            planController.tabBarItem.image = UIImage(named: "calendar")
        }

        if #available(iOS 11.0, *) {
            planController.navigationBar.prefersLargeTitles = true
        }

        return planController
    }

    func makeHomeController() -> HomeController {
        let tracksController = HomeController(services: services)
        tracksController.title = NSLocalizedString("home.title", comment: "")

        if #available(iOS 13.0, *) {
            tracksController.tabBarItem.image = UIImage(systemName: "magnifyingglass")
        } else {
            tracksController.tabBarItem.image = UIImage(named: "magnifyingglass")
        }

        if #available(iOS 11.0, *) {
            tracksController.navigationBar.prefersLargeTitles = true
        }

        return tracksController
    }

    func makeMoreController() -> MoreController {
        let moreController = MoreController(services: services)
        moreController.title = NSLocalizedString("more.title", comment: "")

        if #available(iOS 13.0, *) {
            moreController.tabBarItem.image = UIImage(systemName: "ellipsis.circle")
        } else {
            moreController.tabBarItem.image = UIImage(named: "ellipsis.circle")
        }

        if #available(iOS 11.0, *) {
            moreController.navigationBar.prefersLargeTitles = true
        }

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
