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
        viewControllers.append(makeMoreNavigationController())
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

extension ApplicationController: MoreViewControllerDelegate {
    func moreViewController(_ moreViewController: MoreViewController, didSelect item: MoreItem) {
        switch item {
        case .speakers: moreViewController.show(makeSpeakersViewController(), sender: nil)
        case .acknowledgements: break
        case .transportation: break
        case .years: break
        }
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

extension ApplicationController: SpeakersViewControllerDelegate, SpeakersViewControllerDataSource {
    var people: [Person] {
        [] // FIXME:
    }

    func speakersViewController(_ speakersViewController: SpeakersViewController, didSelect person: Person) {
        print(#function, person, speakersViewController)
    }
}

extension ApplicationController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated _: Bool) {
        switch viewController {
        case _ as MoreViewController: navigationController.setNavigationBarHidden(true, animated: true)
        case _ as SpeakersViewController: navigationController.setNavigationBarHidden(false, animated: true)
        default: break
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
        welcomeViewController.title = NSLocalizedString("FOSDEM", comment: "")
        welcomeViewController.navigationItem.title = NSLocalizedString("Welcome to FOSDEM", comment: "")
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
        mapViewController.title = NSLocalizedString("Map", comment: "")
        return mapViewController
    }

    func makeMoreNavigationController() -> UINavigationController {
        let moreViewController = MoreViewController()
        moreViewController.title = NSLocalizedString("More", comment: "")
        moreViewController.delegate = self

        let navigationController = makeRootNavigationController(with: moreViewController)
        navigationController.setNavigationBarHidden(true, animated: false)
        navigationController.delegate = self
        return navigationController
    }

    func makeSpeakersViewController() -> SpeakersViewController {
        let speakersViewController = SpeakersViewController()
        speakersViewController.title = NSLocalizedString("Speakers", comment: "")
        speakersViewController.hidesBottomBarWhenPushed = true
        speakersViewController.dataSource = self
        speakersViewController.delegate = self

        if #available(iOS 11.0, *) {
            speakersViewController.navigationItem.largeTitleDisplayMode = .never
        }

        return speakersViewController
    }
}
