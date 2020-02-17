import UIKit

final class ApplicationController: UITabBarController {
    private weak var welcomeNavigationController: UINavigationController?

    private let services: Services

    init(services: Services) {
        self.services = services

        super.init(nibName: nil, bundle: nil)

        var viewControllers: [UIViewController] = []
        if favoritesService.eventsIdentifiers.isEmpty {
            viewControllers.append(makeWelcomeNavigationController())
        } else {
            viewControllers.append(PlanController(services: services))
        }

        viewControllers.append(TracksController(services: services))
        viewControllers.append(makeMapViewController())
        viewControllers.append(makeMoreNavigationController())
        setViewControllers(viewControllers, animated: false)

        services.favoritesService.delegate = self
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var favoritesService: FavoritesService {
        services.favoritesService
    }

    private func makeRootNavigationController(with rootViewController: UIViewController) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: rootViewController)

        return navigationController
    }

    private func makeMapViewController() -> MapViewController {
        let mapViewController = MapViewController()
        mapViewController.title = NSLocalizedString("Map", comment: "")
        return mapViewController
    }

    private func makeMoreViewController() -> MoreViewController {
        let moreViewController = MoreViewController()
        moreViewController.title = NSLocalizedString("More", comment: "")
        moreViewController.delegate = self
        return moreViewController
    }

    private func makeMoreNavigationController() -> UINavigationController {
        let navigationController = makeRootNavigationController(with: makeMoreViewController())
        navigationController.setNavigationBarHidden(true, animated: false)
        navigationController.delegate = self
        return navigationController
    }

    private func makeWelcomeViewController() -> WelcomeViewController {
        let welcomeViewController = WelcomeViewController()
        welcomeViewController.title = NSLocalizedString("FOSDEM", comment: "")
        welcomeViewController.navigationItem.title = NSLocalizedString("Welcome to FOSDEM", comment: "")
        welcomeViewController.delegate = self

        if #available(iOS 11.0, *) {
            welcomeViewController.navigationItem.largeTitleDisplayMode = .always
        }

        return welcomeViewController
    }

    private func makeWelcomeNavigationController() -> UINavigationController {
        let welcomeNavigationController = makeRootNavigationController(with: makeWelcomeViewController())
        self.welcomeNavigationController = welcomeNavigationController
        return welcomeNavigationController
    }

    private func makeSpeakersViewController() -> SpeakersViewController {
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

extension ApplicationController: FavoritesServiceDelegate {
    func favoritesServiceDidUpdateTracks(_: FavoritesService) {}

    func favoritesServiceDidUpdateEvents(_: FavoritesService) {}
}
