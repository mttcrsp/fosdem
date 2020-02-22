import UIKit

final class ApplicationController: UITabBarController {
    private weak var welcomeNavigationController: UINavigationController?

    private var observation: NSObjectProtocol?

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

        var viewControllers: [UIViewController] = []
        if hasFavoriteEvents {
            viewControllers.append(PlanController(services: services))
        } else {
            viewControllers.append(makeWelcomeNavigationController())
        }

        viewControllers.append(TracksController(services: services))
        viewControllers.append(makeMapViewController())
        viewControllers.append(MoreController(services: services))
        setViewControllers(viewControllers, animated: false)

        observation = services.favoritesService.addObserverForEvents { [weak self] in
            self?.favoriteEventsChanged()
        }
    }

    private func favoriteEventsChanged() {
        if hasFavoriteEvents, viewControllers?.first == welcomeNavigationController {
            viewControllers?[0] = PlanController(services: services)
        } else if !hasFavoriteEvents, viewControllers?.first is PlanController {
            viewControllers?[0] = makeWelcomeNavigationController()
        }
    }

    private var hasFavoriteEvents: Bool {
        !services.favoritesService.eventsIdentifiers.isEmpty
    }
}

extension ApplicationController: WelcomeViewControllerDelegate {
    func welcomeViewControllerDidTapPlan(_: WelcomeViewController) {
        guard let tabBarController = tabBarController, let viewControllers = tabBarController.viewControllers else { return }

        for (index, viewController) in viewControllers.enumerated() where viewController is TracksController {
            tabBarController.selectedIndex = index
        }
    }
}

private extension ApplicationController {
    func makeRootNavigationController(with rootViewController: UIViewController) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: rootViewController)
        if #available(iOS 11.0, *) {
            navigationController.navigationBar.prefersLargeTitles = true
        }
        return navigationController
    }

    func makeWelcomeNavigationController() -> UINavigationController {
        let welcomeViewController = WelcomeViewController()
        welcomeViewController.title = NSLocalizedString("welcome.title", comment: "")
        welcomeViewController.navigationItem.title = NSLocalizedString("welcome.tab", comment: "")
        welcomeViewController.delegate = self

        if #available(iOS 11.0, *) {
            welcomeViewController.navigationItem.largeTitleDisplayMode = .always
        }

        let navigationController = makeRootNavigationController(with: welcomeViewController)
        welcomeNavigationController = navigationController
        return navigationController
    }

    func makeMapViewController() -> MapViewController {
        let mapViewController = MapViewController()
        mapViewController.title = NSLocalizedString("map.title", comment: "")
        return mapViewController
    }
}
