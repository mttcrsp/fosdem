import UIKit

protocol YearControllerDelegate: AnyObject {
    func yearControllerDidError(_ yearController: YearController)
}

final class YearController: TracksViewController {
    weak var yearDelegate: YearControllerDelegate?

    private weak var resultsViewController: EventsViewController?
    private weak var eventsViewController: EventsViewController?
    private var searchController: UISearchController?

    private var tracks: [Track] = []
    private var events: [Event] = []

    private let year: String
    private let services: Services

    init(year: String, services: Services) {
        self.year = year
        self.services = services
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var persistenceService: PersistenceService {
        services.persistenceService
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
        dataSource = self
        definesPresentationContext = true
        addSearchViewController(makeSearchController())

        persistenceService.performRead(AllTracksOrderedByName()) { result in
            DispatchQueue.main.async { [weak self] in
                switch result {
                case let .failure(error): self?.tracksLoadingDidError(with: error)
                case let .success(tracks): self?.tracksLoadingDidFinish(with: tracks)
                }
            }
        }
    }

    private func tracksLoadingDidError(with _: Error) {
        yearDelegate?.yearControllerDidError(self)
    }

    private func tracksLoadingDidFinish(with tracks: [Track]) {
        self.tracks = tracks
        reloadData()
    }
}

extension YearController: TracksViewControllerDataSource, TracksViewControllerDelegate {
    func numberOfSections(in _: TracksViewController) -> Int {
        1
    }

    func tracksViewController(_: TracksViewController, titleForSectionAt _: Int) -> String? {
        nil
    }

    func tracksViewController(_: TracksViewController, numberOfTracksIn _: Int) -> Int {
        tracks.count
    }

    func tracksViewController(_: TracksViewController, trackAt indexPath: IndexPath) -> Track {
        tracks[indexPath.row]
    }

    func tracksViewController(_ tracksViewController: TracksViewController, didSelect track: Track) {
        let eventsViewController = makeEventsViewController(for: track)
        tracksViewController.show(eventsViewController, sender: nil)

        events = []
        persistenceService.performRead(EventsForTrack(track: track.name)) { result in
            DispatchQueue.main.async { [weak self] in
                switch result {
                case let .failure(error): self?.eventsLoadingDidError(with: error)
                case let .success(events): self?.eventsLoadingDidFinish(with: events)
                }
            }
        }
    }

    private func eventsLoadingDidError(with error: Error) {
        assertionFailure(error.localizedDescription)
        yearDelegate?.yearControllerDidError(self)
    }

    private func eventsLoadingDidFinish(with events: [Event]) {
        self.events = events
        eventsViewController?.reloadData()
    }
}

extension YearController: EventsViewControllerDataSource, EventsViewControllerDelegate {
    func events(in _: EventsViewController) -> [Event] {
        events
    }

    func eventsViewController(_: EventsViewController, captionFor event: Event) -> String? {
        event.formattedPeople
    }

    func eventsViewController(_ presentingViewController: EventsViewController, didSelect event: Event) {
        let eventViewController = makeEventViewController(for: event)

        if presentingViewController == eventsViewController {
            presentingViewController.showDetailViewController(eventViewController, sender: nil)
        } else if presentingViewController == resultsViewController {
            presentingViewController.deselectSelectedRow(animated: true)
            showDetailViewController(eventViewController, sender: nil)
        }
    }
}

extension YearController: UISearchControllerDelegate, UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text, !query.isEmpty else { return }

        let operation = EventsForSearch(query: query)
        persistenceService.performRead(operation) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .failure:
                    break
                case let .success(events):
                    self?.events = events

                    let emptyTitle = NSLocalizedString("search.empty.title", comment: "")
                    let emptyMessageFormat = NSLocalizedString("search.empty.message", comment: "")
                    let emptyMessage = String(format: emptyMessageFormat, query)
                    self?.resultsViewController?.emptyBackgroundMessage = emptyMessage
                    self?.resultsViewController?.emptyBackgroundTitle = emptyTitle
                    self?.resultsViewController?.reloadData()
                }
            }
        }
    }
}

private extension YearController {
    func makeSearchController() -> UISearchController {
        let searchController = UISearchController(searchResultsController: makeResultsViewController())
        searchController.searchBar.placeholder = NSLocalizedString("more.search.prompt", comment: "")
        searchController.searchResultsUpdater = self
        self.searchController = searchController
        return searchController
    }

    func makeResultsViewController() -> EventsViewController {
        let resultsViewController = EventsViewController(style: .grouped)
        resultsViewController.dataSource = self
        resultsViewController.delegate = self
        self.resultsViewController = resultsViewController
        return resultsViewController
    }

    func makeEventsViewController(for track: Track) -> EventsViewController {
        let eventsViewController = EventsViewController(style: .grouped)
        eventsViewController.title = track.name
        eventsViewController.dataSource = self
        eventsViewController.delegate = self
        self.eventsViewController = eventsViewController
        return eventsViewController
    }

    func makeEventViewController(for event: Event) -> EventController {
        let eventViewController = EventController(event: event, services: services)
        eventViewController.showsFavoriteButton = false
        return eventViewController
    }
}
