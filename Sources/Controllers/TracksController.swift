import UIKit

private enum TracksFilter: Equatable, Hashable {
    case all, favorites, day(Int)
}

private struct TracksSection {
    let initial: Character, tracks: [Track]
}

final class TracksController: UINavigationController {
    private weak var tracksViewController: TracksViewController?
    private weak var eventsViewController: EventsViewController?

    private var sections: [TracksFilter: [TracksSection]] = [:]
    private var filters: [TracksFilter] = []
    private var events: [Event] = []
    private var tracks: [Track] = []

    private var observation: NSObjectProtocol?
    private var selectedFilter: TracksFilter = .all
    private var selectedTrack: Track?

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

        viewControllers = [makeTracksViewController()]

        persistenceService.performRead(AllTracksOrderedByName()) { [weak self] result in
            switch result {
            case let .failure(error): self?.loadingDidFail(with: error)
            case let .success(tracks): self?.loadingDidFinish(with: tracks)
            }
        }

        observation = favoritesService.addObserverForTracks { [weak self] in
            guard let self = self else { return }

            self.sections[.favorites] = self.makeSections(from: self.tracks.filter { track in
                self.favoritesService.tracksIdentifiers.contains(track.name)
            })

            if self.selectedFilter == .favorites {
                self.tracksViewController?.reloadData()
            }
        }
    }

    private func loadingDidFail(with _: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.viewControllers = [ErrorController()]
        }
    }

    private func loadingDidFinish(with tracks: [Track]) {
        self.tracks = tracks

        var days: Set<Int> = []
        for track in tracks {
            days.insert(track.day)
        }

        filters = makeFilters(withDaysCount: days.count)

        sections = [:]
        for filter in filters {
            switch filter {
            case .all:
                sections[filter] = makeSections(from: tracks)
            case let .day(day):
                sections[filter] = makeSections(from: tracks.filter { track in
                    track.day == day
                })
            case .favorites:
                sections[filter] = makeSections(from: tracks.filter { track in
                    favoritesService.tracksIdentifiers.contains(track.name)
                })
            }
        }

        DispatchQueue.main.async { [weak self] in
            self?.tracksViewController?.reloadData()
        }
    }

    private func makeFilters(withDaysCount days: Int) -> [TracksFilter] {
        var filters: [TracksFilter] = []
        filters.append(.all)
        filters.append(contentsOf: (0 ..< days).map { index in .day(index + 1) })
        filters.append(.favorites)
        return filters
    }

    private func makeSections(from tracks: [Track]) -> [TracksSection] {
        var tracksForInitial: [Character: [Track]] = [:]

        for track in tracks {
            if let initial = track.name.first {
                tracksForInitial[initial, default: []].append(track)
            } else {
                assertionFailure("Unexpectedly found no name for track '\(track)'")
            }
        }

        return tracksForInitial
            .sorted { lhs, rhs in lhs.key < rhs.key }
            .map { initial, tracks in .init(initial: initial, tracks: tracks) }
    }
}

extension TracksController: TracksViewControllerDataSource, TracksViewControllerDelegate {
    private var selectedSections: [TracksSection] {
        sections[selectedFilter] ?? []
    }

    func numberOfSections(in _: TracksViewController) -> Int {
        selectedSections.count
    }

    func sectionIndexTitles(for _: TracksViewController) -> [String]? {
        switch selectedFilter {
        case .favorites: return nil
        case .all, .day: return selectedSections.map { section in String(section.initial) }
        }
    }

    func tracksViewController(_: TracksViewController, numberOfTracksIn section: Int) -> Int {
        selectedSections[section].tracks.count
    }

    func tracksViewController(_: TracksViewController, trackAt indexPath: IndexPath) -> Track {
        selectedSections[indexPath.section].tracks[indexPath.row]
    }

    func tracksViewController(_ tracksViewController: TracksViewController, didSelect track: Track) {
        selectedTrack = track

        let eventsViewController = makeEventsViewController(for: track)
        tracksViewController.show(eventsViewController, sender: nil)

        events = []
        persistenceService.performRead(EventsForTrack(track: track.name)) { result in
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

extension TracksController: TracksViewControllerFavoritesDataSource, TracksViewControllerFavoritesDelegate {
    func tracksViewController(_: TracksViewController, canFavoriteTrackAt indexPath: IndexPath) -> Bool {
        !favoritesService.contains(selectedSections[indexPath.section].tracks[indexPath.row])
    }

    func tracksViewController(_: TracksViewController, didFavorite track: Track) {
        favoritesService.addTrack(withIdentifier: track.name)
    }

    func tracksViewController(_: TracksViewController, didUnfavorite track: Track) {
        favoritesService.removeTrack(withIdentifier: track.name)
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
        tracksViewController.favoritesDataSource = self
        tracksViewController.favoritesDelegate = self
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
        .init(event: event, favoritesService: favoritesService)
    }
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
