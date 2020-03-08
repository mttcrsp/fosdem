import UIKit

final class TracksController: UINavigationController {
    private weak var tracksViewController: TracksViewController?
    private weak var eventsViewController: EventsViewController?

    private(set) var favoriteTracks: [Track] = []
    private(set) var tracksForDay: [[Track]] = []
    private(set) var tracks: [Track] = []

    private var events: [Event] = []
    private var filters: [TracksFilter] = []
    private var selectedFilter: TracksFilter = .all
    private var selectedTrack: Track?

    private var observation: NSObjectProtocol?

    private let services: Services

    init(services: Services) {
        self.services = services
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var favoritesService: FavoritesService {
        services.favoritesService
    }

    private var persistenceService: PersistenceService {
        services.persistenceService
    }

    private var favoriteTitle: String? {
        guard let selectedTrack = selectedTrack else {
            return nil
        }

        if favoritesService.contains(selectedTrack) {
            return NSLocalizedString("unfavorite", comment: "")
        } else {
            return NSLocalizedString("favorite", comment: "")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let tracksViewController = makeTracksViewController()

        if #available(iOS 11.0, *) {
            navigationBar.prefersLargeTitles = true
        }

        viewControllers = [tracksViewController]

        persistenceService.tracks { result in
            DispatchQueue.main.async { [weak self] in
                switch result {
                case let .failure(error): self?.loadingDidFail(with: error)
                case let .success(tracks): self?.loadingDidFinish(with: tracks)
                }
            }
        }

        observation = favoritesService.addObserverForTracks { [weak self] in
            guard let self = self else { return }

            self.favoriteTracks = []
            for track in self.tracks where self.favoritesService.contains(track) {
                self.favoriteTracks.append(track)
            }
            self.favoriteTracks.sortByName()

            if self.selectedFilter == .favorites {
                self.tracksViewController?.reloadData()
            }
        }
    }

    private func loadingDidFail(with _: Error) {
        viewControllers = [ErrorController()]
    }

    private func loadingDidFinish(with tracks: [Track]) {
        var tracksForDay: [Int: [Track]] = [:]
        for track in tracks {
            tracksForDay[track.day, default: []].append(track)

            if favoritesService.contains(track) {
                favoriteTracks.append(track)
            }
        }

        self.tracks = tracks
        self.tracks.sortByName()

        favoriteTracks.sortByName()

        self.tracksForDay = tracksForDay
            .sorted { lhs, rhs in lhs.key < rhs.key }
            .map { _, tracks in tracks }

        for i in self.tracksForDay.indices {
            self.tracksForDay[i].sortByName()
        }

        filters = []
        filters.append(.all)
        filters.append(contentsOf: (1 ... tracksForDay.count).map { number in .day(number) })
        filters.append(.favorites)

        tracksViewController?.reloadData()
    }
}

extension TracksController: TracksViewControllerDataSource, TracksViewControllerDelegate {
    private var filteredTracks: [Track] {
        switch selectedFilter {
        case .all: return tracks
        case .favorites: return favoriteTracks
        case let .day(number): return tracksForDay[number - 1]
        }
    }

    func numberOfTracks(in _: TracksViewController) -> Int {
        filteredTracks.count
    }

    func tracksViewController(_: TracksViewController, trackAt indexPath: IndexPath) -> Track {
        filteredTracks[indexPath.row]
    }

    func tracksViewController(_: TracksViewController, canFavoriteTrackAt indexPath: IndexPath) -> Bool {
        !favoritesService.contains(filteredTracks[indexPath.row])
    }

    func tracksViewController(_: TracksViewController, didFavorite track: Track) {
        favoritesService.addTrack(withIdentifier: track.name)
    }

    func tracksViewController(_: TracksViewController, didUnfavorite track: Track) {
        favoritesService.removeTrack(withIdentifier: track.name)
    }

    func tracksViewController(_ tracksViewController: TracksViewController, didSelect track: Track) {
        selectedTrack = track

        let eventsViewController = makeEventsViewController(for: track)
        tracksViewController.show(eventsViewController, sender: nil)

        events = []
        persistenceService.events(forTrackWithIdentifier: track.name) { result in
            DispatchQueue.main.async { [weak self] in
                switch result {
                case .failure:
                    self?.eventsViewController?.present(ErrorController(), animated: true)
                case let .success(events):
                    self?.events = events
                    self?.eventsViewController?.reloadData()
                }
            }
        }
    }

    @objc private func didTapChangeFilter() {
        let filtersViewController = makeFiltersViewController(with: filters, selectedFilter: selectedFilter)
        tracksViewController?.present(filtersViewController, animated: true)
    }

    private func didSelectFilter(_ filter: TracksFilter) {
        selectedFilter = filter
        tracksViewController?.reloadData()
    }
}

extension TracksController: EventsViewControllerDataSource, EventsViewControllerDelegate {
    func events(in _: EventsViewController) -> [Event] {
        events
    }

    func eventsViewController(_ eventsViewController: EventsViewController, didSelect event: Event) {
        eventsViewController.show(makeEventViewController(for: event), sender: nil)
    }

    @objc private func didToggleFavorite() {
        guard let selectedTrack = selectedTrack else { return }

        if favoritesService.contains(selectedTrack) {
            favoritesService.removeTrack(withIdentifier: selectedTrack.name)
        } else {
            favoritesService.addTrack(withIdentifier: selectedTrack.name)
        }
    }
}

private extension TracksController {
    func makeTracksViewController() -> TracksViewController {
        let filtersTitle = NSLocalizedString("tracks.filter.title", comment: "")
        let filtersAction = #selector(didTapChangeFilter)
        let filtersButton = UIBarButtonItem(title: filtersTitle, style: .plain, target: self, action: filtersAction)

        let tracksViewController = TracksViewController()
        tracksViewController.title = NSLocalizedString("tracks.title", comment: "")
        tracksViewController.navigationItem.rightBarButtonItem = filtersButton
        tracksViewController.dataSource = self
        tracksViewController.delegate = self
        self.tracksViewController = tracksViewController

        if #available(iOS 11.0, *) {
            tracksViewController.navigationItem.largeTitleDisplayMode = .always
        }

        return tracksViewController
    }

    func makeFiltersViewController(with filters: [TracksFilter], selectedFilter: TracksFilter) -> UIAlertController {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        for filter in filters where filter != selectedFilter {
            let actionHandler: (UIAlertAction) -> Void = { [weak self] _ in self?.didSelectFilter(filter) }
            let action = UIAlertAction(title: filter.title, style: .default, handler: actionHandler)
            alertController.addAction(action)
        }

        let cancelTitle = NSLocalizedString("tracks.filter.cancel", comment: "")
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel)
        alertController.addAction(cancelAction)

        return alertController
    }

    func makeEventsViewController(for track: Track) -> EventsViewController {
        let favoriteAction = #selector(didToggleFavorite)
        let favoriteButton = UIBarButtonItem(title: favoriteTitle, style: .plain, target: self, action: favoriteAction)

        let eventsViewController = EventsViewController(style: .grouped)
        eventsViewController.navigationItem.rightBarButtonItem = favoriteButton
        eventsViewController.extendedLayoutIncludesOpaqueBars = true
        eventsViewController.hidesBottomBarWhenPushed = true
        eventsViewController.title = track.name
        eventsViewController.dataSource = self
        eventsViewController.delegate = self
        self.eventsViewController = eventsViewController

        if #available(iOS 11.0, *) {
            eventsViewController.navigationItem.largeTitleDisplayMode = .always
        }

        observation = favoritesService.addObserverForTracks { [weak favoriteButton, weak self] in
            favoriteButton?.title = self?.favoriteTitle
        }

        return eventsViewController
    }

    func makeEventViewController(for event: Event) -> EventController {
        .init(event: event, services: services)
    }
}

private extension Array where Element == Track {
    mutating func sortByName() {
        sort { lhs, rhs in lhs.name < rhs.name }
    }
}

enum TracksFilter: Equatable {
    case all, favorites, day(Int)
}

private extension TracksFilter {
    var title: String {
        switch self {
        case .all:
            return NSLocalizedString("tracks.filter.all", comment: "")
        case .favorites:
            return NSLocalizedString("tracks.filter.favorites", comment: "")
        case let .day(day):
            return String(format: NSLocalizedString("tracks.filter.day", comment: ""), day)
        }
    }
}
