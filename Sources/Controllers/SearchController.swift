import UIKit

private enum TracksFilter: Equatable, Hashable {
    case all, favorites, day(Int)
}

private struct TracksSection {
    let initial: Character, tracks: [Track]
}

final class SearchController: UISplitViewController {
    private weak var resultsViewController: EventsViewController?
    private weak var tracksViewController: TracksViewController?
    private weak var eventsViewController: EventsViewController?
    private weak var searchController: UISearchController?

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

        let tracksViewController = makeTracksViewController()
        let tracksNavigationController = UINavigationController(rootViewController: tracksViewController)

        if #available(iOS 11.0, *) {
            tracksNavigationController.navigationBar.prefersLargeTitles = true
        }

        viewControllers = [tracksNavigationController]

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
            .map { initial, tracks in TracksSection(initial: initial, tracks: tracks) }
    }
}

extension SearchController: TracksViewControllerDataSource, TracksViewControllerDelegate {
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
        guard track != selectedTrack else { return }

        selectedTrack = track

        let eventsViewController = makeEventsViewController(for: track)
        let eventsNavigationController = UINavigationController(rootViewController: eventsViewController)
        tracksViewController.showDetailViewController(eventsNavigationController, sender: nil)

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

extension SearchController: TracksViewControllerFavoritesDataSource, TracksViewControllerFavoritesDelegate {
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

extension SearchController: EventsViewControllerDataSource, EventsViewControllerDelegate, EventsViewControllerFavoritesDataSource, EventsViewControllerFavoritesDelegate {
    func events(in _: EventsViewController) -> [Event] {
        events
    }

    func eventsViewController(_ viewController: EventsViewController, didSelect event: Event) {
        switch viewController {
        case eventsViewController: trackViewController(viewController, didSelect: event)
        case resultsViewController: resultsViewController(viewController, didSelect: event)
        default: break
        }
    }

    private func trackViewController(_ trackViewController: EventsViewController, didSelect event: Event) {
        let eventViewController = makeEventViewController(for: event)
        trackViewController.show(eventViewController, sender: nil)
    }

    private func resultsViewController(_: EventsViewController, didSelect event: Event) {
        let eventViewController = makeEventViewController(for: event)
        tracksViewController?.showDetailViewController(eventViewController, sender: nil)

        if traitCollection.horizontalSizeClass == .regular {
            searchController?.searchBar.endEditing(true)
        }
    }

    func eventsViewController(_: EventsViewController, canFavorite event: Event) -> Bool {
        !favoritesService.contains(event)
    }

    func eventsViewController(_: EventsViewController, didFavorite event: Event) {
        favoritesService.addEvent(withIdentifier: event.id)
    }

    func eventsViewController(_: EventsViewController, didUnfavorite event: Event) {
        favoritesService.removeEvent(withIdentifier: event.id)
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

extension SearchController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text, query.count >= 3 else {
            resultsViewController?.emptyBackgroundText = nil
            resultsViewController?.view.isHidden = true
            events = []
            return
        }

        let operation = EventsForSearch(query: query)
        services.persistenceService.performRead(operation) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .failure:
                    break
                case let .success(events):
                    self?.events = events

                    let emptyFormat = NSLocalizedString("more.search.empty", comment: "")
                    let emptyString = String(format: emptyFormat, query)
                    self?.resultsViewController?.emptyBackgroundText = emptyString
                    self?.resultsViewController?.view.isHidden = false
                    self?.resultsViewController?.reloadData()
                }
            }
        }
    }
}

private extension SearchController {
    func makeTracksViewController() -> TracksViewController {
        let filtersTitle = NSLocalizedString("search.filter.title", comment: "")
        let filtersAction = #selector(didTapChangeFilter)
        let filtersButton = UIBarButtonItem(title: filtersTitle, style: .plain, target: self, action: filtersAction)

        let tracksViewController = TracksViewController()
        tracksViewController.title = NSLocalizedString("search.title", comment: "")
        tracksViewController.navigationItem.rightBarButtonItem = filtersButton
        tracksViewController.addSearchViewController(makeSearchController())
        tracksViewController.extendedLayoutIncludesOpaqueBars = true
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

        let cancelTitle = NSLocalizedString("search.filter.cancel", comment: "")
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel)
        alertController.addAction(cancelAction)

        return alertController
    }

    func makeSearchController() -> UISearchController {
        let searchController = UISearchController(searchResultsController: makeResultsViewController())
        searchController.searchBar.placeholder = NSLocalizedString("more.search.prompt", comment: "")
        searchController.searchResultsUpdater = self
        self.searchController = searchController
        return searchController
    }

    func makeResultsViewController() -> EventsViewController {
        let resultsViewController = EventsViewController()
        resultsViewController.favoritesDataSource = self
        resultsViewController.favoritesDelegate = self
        resultsViewController.dataSource = self
        resultsViewController.delegate = self
        self.resultsViewController = resultsViewController
        return resultsViewController
    }

    func makeEventsViewController(for track: Track) -> EventsViewController {
        let favoriteAction = #selector(didToggleFavorite)
        let favoriteButton = UIBarButtonItem(title: favoriteTitle, style: .plain, target: self, action: favoriteAction)

        let eventsViewController = EventsViewController()
        eventsViewController.navigationItem.rightBarButtonItem = favoriteButton
        eventsViewController.extendedLayoutIncludesOpaqueBars = true
        eventsViewController.favoritesDataSource = self
        eventsViewController.favoritesDelegate = self
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
        let eventViewController = EventController(event: event, favoritesService: favoritesService)
        eventViewController.extendedLayoutIncludesOpaqueBars = true
        return eventViewController
    }
}

private extension TracksFilter {
    var title: String {
        switch self {
        case .all:
            return NSLocalizedString("search.filter.all", comment: "")
        case .favorites:
            return NSLocalizedString("search.filter.favorites", comment: "")
        case let .day(day):
            return String(format: NSLocalizedString("search.filter.day", comment: ""), day)
        }
    }
}
