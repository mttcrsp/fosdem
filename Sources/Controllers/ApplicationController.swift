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
            viewControllers.append(makePlanController())
        } else {
            viewControllers.append(makeWelcomeNavigationController())
        }

        viewControllers.append(makeTracksController())
        viewControllers.append(makeMapViewController())
        viewControllers.append(makeMoreController())
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
    func makeWelcomeNavigationController() -> UINavigationController {
        let welcomeViewController = WelcomeViewController()
        welcomeViewController.title = NSLocalizedString("welcome.title", comment: "")
        welcomeViewController.navigationItem.title = NSLocalizedString("welcome.tab", comment: "")
        welcomeViewController.delegate = self

        if #available(iOS 11.0, *) {
            welcomeViewController.navigationItem.largeTitleDisplayMode = .always
        }

        let navigationController = UINavigationController(rootViewController: welcomeViewController)
        if #available(iOS 11.0, *) {
            navigationController.navigationBar.prefersLargeTitles = true
        }

        welcomeNavigationController = navigationController
        return navigationController
    }

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

    func makeMapViewController() -> MapViewController {
        let mapViewController = MapViewController()
        mapViewController.title = NSLocalizedString("map.title", comment: "")
        return mapViewController
    }

    func makeMoreController() -> MoreController {
        let moreController = MoreController(services: services)
        moreController.title = NSLocalizedString("more.title", comment: "")
        return moreController
    }
}
