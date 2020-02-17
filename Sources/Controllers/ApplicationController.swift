import AVKit
import UIKit

final class ApplicationController: UITabBarController {
    private weak var tracksNavigationController: UINavigationController?
    private weak var tracksViewController: TracksViewController?

    private weak var planNavigationController: UINavigationController?
    private weak var planViewController: PlanViewController?

    private weak var welcomeNavigationController: UINavigationController?
    private weak var eventViewController: EventViewController?

    private var selectedTrack: Track?

    private let services: Services

    init(services: Services) {
        self.services = services

        super.init(nibName: nil, bundle: nil)

        var viewControllers: [UIViewController] = []
        if favoritesService.eventsIdentifiers.isEmpty {
            viewControllers.append(makeWelcomeNavigationController())
        } else {
            viewControllers.append(makePlanNavigationController())
        }

        viewControllers.append(makeTracksNavigationController())
        viewControllers.append(makeMapViewController())
        viewControllers.append(makeMoreNavigationController())
        setViewControllers(viewControllers, animated: false)

        self.services.favoritesService.delegate = self
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var favoritesService: FavoritesService {
        services.favoritesService
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

    private func makeTracksNavigationController() -> UINavigationController {
        let tracksNavigationController = makeRootNavigationController(with: makeTracksViewController())
        self.tracksNavigationController = tracksNavigationController
        return tracksNavigationController
    }

    private func makeEventsViewController(for track: Track) -> EventsViewController {
        let eventsViewController = EventsViewController()
        eventsViewController.hidesBottomBarWhenPushed = true
        eventsViewController.title = track.name
        eventsViewController.dataSource = self
        eventsViewController.delegate = self

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

    private func makePlanNavigationController() -> UINavigationController {
        let planNavigationController = makeRootNavigationController(with: makePlanViewController())
        self.planNavigationController = planNavigationController
        return planNavigationController
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

    private func makeVideoViewController(for url: URL) -> AVPlayerViewController {
        let videoViewController = AVPlayerViewController()
        videoViewController.player = AVPlayer(url: url)
        videoViewController.player?.play()
        videoViewController.allowsPictureInPicturePlayback = true

        if #available(iOS 11.0, *) {
            videoViewController.exitsFullScreenWhenPlaybackEnds = true
        }

        return videoViewController
    }
}

extension ApplicationController: TracksViewControllerDataSource, TracksViewControllerDelegate {
    var tracks: [Track] {
        [] // FIXME:
    }

    var tracksForDay: [[Track]] {
        [] // FIXME:
    }

    var favoriteTracks: [Track] {
        [] // FIXME:
    }

    func tracksViewController(_: TracksViewController, didFavorite track: Track) {
        _ = track // FIXME:
    }

    func tracksViewController(_: TracksViewController, didUnfavorite track: Track) {
        _ = track // FIXME:
    }

    func tracksViewController(_ tracksViewController: TracksViewController, didSelect track: Track) {
        selectedTrack = tracksViewController.selectedTrack
        tracksViewController.show(makeEventsViewController(for: track), sender: nil)
    }
}

extension ApplicationController: EventsViewControllerDataSource, EventsViewControllerDelegate {
    func events(in _: EventsViewController) -> [Event] {
        [] // FIXME:
    }

    func eventsViewController(_ eventsViewController: EventsViewController, didSelect event: Event) {
        eventsViewController.show(makeEventViewController(for: event), sender: nil)
    }
}

extension ApplicationController: EventViewControllerDataSource, EventViewControllerDelegate {
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

    func eventViewControllerDidTapVideo(_ eventViewController: EventViewController) {
        guard let event = eventViewController.event, let video = event.video, let url = video.url else { return }
        eventViewController.present(makeVideoViewController(for: url), animated: true)
    }
}

extension ApplicationController: PlanViewControllerDataSource, PlanViewControllerDelegate {
    func events(in _: PlanViewController) -> [Event] {
        [] // FIXME:
    }

    func planViewController(_ planViewController: PlanViewController, didSelect event: Event) {
        planViewController.show(makeEventViewController(for: event), sender: nil)
    }

    func planViewController(_: PlanViewController, didUnfavorite event: Event) {
        favoritesService.removeEvent(withIdentifier: event.id)
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

        for (index, viewController) in viewControllers.enumerated() where viewController == tracksNavigationController {
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
    func favoritesServiceDidUpdateTracks(_: FavoritesService) {
        tracksViewController?.reloadFavorites()
    }

    func favoritesServiceDidUpdateEvents(_ favoritesService: FavoritesService) {
        let hasFavoriteEvents = !favoritesService.eventsIdentifiers.isEmpty
        let firstViewController = tabBarController?.viewControllers?.first

        switch (hasFavoriteEvents, firstViewController) {
        case (true, welcomeNavigationController): tabBarController?.viewControllers?[0] = makePlanNavigationController()
        case (false, planNavigationController): tabBarController?.viewControllers?[0] = makeWelcomeNavigationController()
        default: break
        }

        planViewController?.reloadData()
        eventViewController?.reloadFavoriteState()
    }
}
