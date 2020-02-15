import UIKit
import XMLCoder

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    private weak var tracksViewController: TracksViewController?
    private weak var eventViewController: EventViewController?
    private weak var planViewController: PlanViewController?
    private weak var tabBarController: UITabBarController?

    private var selectedTrack: Track?
    private var indices: TracksIndices?

    private lazy var services = Services()

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        #if DEBUG
            guard !isRunningUnitTests else { return false }
        #endif

        window = UIWindow()
        window?.rootViewController = makeTabBarController()
        window?.makeKeyAndVisible()

        services.favoritesService.delegate = self

        DispatchQueue.global().async { [weak self] in
            guard let url = Bundle.main.url(forResource: "2020", withExtension: "xml"), let data = try? Data(contentsOf: url), let schedule = try? XMLDecoder.default.decode(Schedule.self, from: data) else { return }

            // The Schedule API does not model tracks with an explicit model.
            // Tracks information is stored within the event model itself. This
            // means that in order to be able to get the list of all tracks you
            // need to traverse all events, collect all tracks identifiers and
            // sort them. Given that most recent conferences had 400+ events,
            // this takes a while.
            self?.indices = .init(schedule: schedule)

            DispatchQueue.main.async {
                self?.tracksViewController?.reloadData()
            }
        }

        return true
    }

    func makeTabBarController() -> UIViewController {
        var rootViewControllers: [UIViewController] = []

        if favoritesService.eventsIdentifiers.isEmpty {
            let welcomeViewController = makeWelcomeViewController()
            rootViewControllers.append(makeRootNavigationController(with: welcomeViewController))
        } else {
            let planViewController = makePlanViewController()
            rootViewControllers.append(makeRootNavigationController(with: planViewController))
        }

        let tracksViewController = makeTracksViewController()
        rootViewControllers.append(makeRootNavigationController(with: tracksViewController))
        rootViewControllers.append(makeMapViewController())
        rootViewControllers.append(makeMoreViewController())

        let tabBarController = UITabBarController()
        tabBarController.setViewControllers(rootViewControllers, animated: false)
        self.tabBarController = tabBarController
        return tabBarController
    }

    private func makeRootNavigationController(with rootViewController: UIViewController) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: rootViewController)
        if #available(iOS 11.0, *) {
            navigationController.navigationBar.prefersLargeTitles = true
        }
        return navigationController
    }

    private func makeTracksViewController() -> TracksViewController {
        let tracksViewController = TracksViewController()
        tracksViewController.delegate = self
        tracksViewController.dataSource = self
        tracksViewController.title = NSLocalizedString("Tracks", comment: "")
        self.tracksViewController = tracksViewController

        if #available(iOS 11.0, *) {
            tracksViewController.navigationItem.largeTitleDisplayMode = .always
        }

        return tracksViewController
    }

    private func makeEventsViewController(for track: Track) -> EventsViewController {
        let eventsViewController = EventsViewController()
        eventsViewController.hidesBottomBarWhenPushed = true
        eventsViewController.dataSource = self
        eventsViewController.delegate = self
        eventsViewController.title = track

        if #available(iOS 11.0, *) {
            eventsViewController.navigationItem.largeTitleDisplayMode = .always
        }

        return eventsViewController
    }

    private func makeEventViewController(for event: Event) -> EventViewController {
        let eventViewController = EventViewController()
        eventViewController.hidesBottomBarWhenPushed = true
        eventViewController.dataSource = self
        eventViewController.delegate = self
        eventViewController.event = event
        self.eventViewController = eventViewController

        if #available(iOS 11.0, *) {
            eventViewController.navigationItem.largeTitleDisplayMode = .never
        }

        return eventViewController
    }

    private func makePlanViewController() -> PlanViewController {
        let planViewController = PlanViewController()
        planViewController.title = NSLocalizedString("Plan", comment: "")
        planViewController.dataSource = self
        planViewController.delegate = self
        self.planViewController = planViewController

        if #available(iOS 11.0, *) {
            planViewController.navigationItem.largeTitleDisplayMode = .always
        }

        return planViewController
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
}

extension AppDelegate: TracksViewControllerDataSource, TracksViewControllerDelegate {
    private var favoritesService: FavoritesService {
        services.favoritesService
    }

    var tracks: [Track] {
        indices?.tracks ?? []
    }

    var tracksForDay: [[Track]] {
        indices?.tracksForDay ?? []
    }

    var favoriteTracks: [Track] {
        favoritesService.tracks.sorted()
    }

    func tracksViewController(_: TracksViewController, didFavorite track: Track) {
        favoritesService.addTrack(track)
    }

    func tracksViewController(_: TracksViewController, didUnfavorite track: Track) {
        favoritesService.removeTrack(track)
    }

    func tracksViewController(_ tracksViewController: TracksViewController, didSelect track: Track) {
        selectedTrack = tracksViewController.selectedTrack
        tracksViewController.show(makeEventsViewController(for: track), sender: nil)
    }
}

extension AppDelegate: EventsViewControllerDataSource, EventsViewControllerDelegate {
    func events(in _: EventsViewController) -> [Event] {
        guard let selectedTrack = selectedTrack, let eventsForTrack = indices?.eventsForTrack else { return [] }
        return eventsForTrack[selectedTrack] ?? []
    }

    func eventsViewController(_ eventsViewController: EventsViewController, didSelect event: Event) {
        eventsViewController.show(makeEventViewController(for: event), sender: nil)
    }
}

extension AppDelegate: EventViewControllerDataSource, EventViewControllerDelegate {
    func isEventFavorite(for eventViewController: EventViewController) -> Bool {
        guard let event = eventViewController.event else { return false }
        return favoritesService.eventsIdentifiers.contains(event.id)
    }

    func eventViewControllerDidTapFavorite(_ eventViewController: EventViewController) {
        guard let event = eventViewController.event else { return }

        if isEventFavorite(for: eventViewController) {
            favoritesService.removeEvent(withIdentifier: event.id)
        } else {
            favoritesService.addEvent(withIdentifier: event.id)
        }
    }
}

extension AppDelegate: PlanViewControllerDataSource, PlanViewControllerDelegate {
    func events(in _: PlanViewController) -> [Event] {
        favoritesService.eventsIdentifiers.sorted().compactMap { identifier in
            indices?.eventForIdentifier[identifier]
        }
    }

    func planViewController(_ planViewController: PlanViewController, didSelect event: Event) {
        planViewController.show(makeEventViewController(for: event), sender: nil)
    }

    func planViewController(_: PlanViewController, didUnfavorite event: Event) {
        favoritesService.removeEvent(withIdentifier: event.id)
    }
}

extension AppDelegate: MoreViewControllerDelegate {
    func moreViewController(_ moreViewController: MoreViewController, didSelect item: MoreItem) {
        print(#function, item, moreViewController)
    }
}

extension AppDelegate: WelcomeViewControllerDelegate {
    func welcomeViewControllerDidTapPlan(_: WelcomeViewController) {
        guard let tabBarController = tabBarController, let viewControllers = tabBarController.viewControllers else { return }

        for (index, viewController) in viewControllers.enumerated() {
            if let navigationController = viewController as? UINavigationController, navigationController.viewControllers.first is TracksViewController {
                tabBarController.selectedIndex = index
            }
        }
    }
}

extension AppDelegate: FavoritesServiceDelegate {
    func favoritesServiceDidUpdateTracks(_: FavoritesService) {
        tracksViewController?.reloadFavorites()
    }

    func favoritesServiceDidUpdateEvents(_ favoritesService: FavoritesService) {
        let hasFavoriteEvents = !favoritesService.eventsIdentifiers.isEmpty
        let firstNavigationController = tabBarController?.viewControllers?.first as? UINavigationController
        let firstViewController = firstNavigationController?.viewControllers.first

        switch (hasFavoriteEvents, firstViewController) {
        case (true, _ as WelcomeViewController):
            let planViewController = makePlanViewController()
            let planNavigationController = makeRootNavigationController(with: planViewController)
            tabBarController?.viewControllers?[0] = planNavigationController
        case (false, _ as PlanViewController):
            let welcomeViewController = makeWelcomeViewController()
            let welcomeNavigationController = makeRootNavigationController(with: welcomeViewController)
            tabBarController?.viewControllers?[0] = welcomeNavigationController
        default:
            break
        }

        planViewController?.reloadData()
        eventViewController?.reloadFavoriteState()
    }
}

#if DEBUG
    private extension AppDelegate {
        var isRunningUnitTests: Bool {
            CommandLine.arguments.contains("-ApplePersistenceIgnoreState")
        }
    }
#endif
