import UIKit
import XMLCoder

typealias Track = String

final class ApplicationController {
    private weak var tracksViewController: TracksViewController?
    private weak var eventViewController: EventViewController?
    private weak var planViewController: PlanViewController?

    private var selectedTrack: Track?
    private var indices: TracksIndices?

    private let services = Services()

    init() {
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
    }

    func makeRootViewController() -> UIViewController {
        let tracksViewController = makeTracksViewController()
        let tracksNavigationController = UINavigationController(rootViewController: tracksViewController)

        let planViewController = makePlanViewController()
        let planNavigationController = UINavigationController(rootViewController: planViewController)

        let navigationControllers = [tracksNavigationController, planNavigationController]
        if #available(iOS 11.0, *) {
            for navigationController in navigationControllers {
                navigationController.navigationBar.prefersLargeTitles = true
            }
        }

        let tabBarController = UITabBarController()
        tabBarController.setViewControllers(navigationControllers, animated: false)
        return tabBarController
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
        return planViewController
    }
}

extension ApplicationController: TracksViewControllerDataSource, TracksViewControllerDelegate {
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
        favoritesService.tracks
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

extension ApplicationController: EventsViewControllerDataSource, EventsViewControllerDelegate {
    func events(in _: EventsViewController) -> [Event] {
        guard let selectedTrack = selectedTrack, let eventsForTrack = indices?.eventsForTrack else { return [] }
        return eventsForTrack[selectedTrack] ?? []
    }

    func eventsViewController(_ eventsViewController: EventsViewController, didSelect event: Event) {
        eventsViewController.show(makeEventViewController(for: event), sender: nil)
    }
}

extension ApplicationController: EventViewControllerDataSource, EventViewControllerDelegate {
    func isEventFavorite(for eventViewController: EventViewController) -> Bool {
        guard let event = eventViewController.event else { return false }
        return favoritesService.containsEvent(withIdentifier: event.id)
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

extension ApplicationController: PlanViewControllerDataSource, PlanViewControllerDelegate {
    func events(in _: PlanViewController) -> [Event] {
        indices?.eventsForTrack["LLVM"] ?? []
    }

    func planViewController(_ planViewController: PlanViewController, didSelect event: Event) {
        planViewController.show(makeEventViewController(for: event), sender: nil)
    }

    func planViewController(_: PlanViewController, didUnfavorite event: Event) {
        favoritesService.removeEvent(withIdentifier: event.id)
    }
}

extension ApplicationController: FavoritesServiceDelegate {
    func favoritesServiceDidUpdateTracks(_: FavoritesService) {
        tracksViewController?.reloadFavorites()
    }

    func favoritesServiceDidUpdateEvents(_: FavoritesService) {
        eventViewController?.reloadFavoriteState()
        planViewController?.reloadData()
    }
}
