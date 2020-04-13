import UIKit

protocol YearControllerDelegate: AnyObject {
    func yearControllerDidError(_ yearController: YearController)
}

final class YearController: UIViewController {
    weak var delegate: YearControllerDelegate?

    private weak var resultsViewController: EventsViewController?
    private weak var eventsViewController: EventsViewController?
    private weak var tracksViewController: TracksViewController?
    private var searchController: UISearchController?

    private var tracks: [Track] = []
    private var events: [Event] = []

    private let year: String
    private let persistenceService: PersistenceService

    init(year: String, persistenceService: PersistenceService) {
        self.year = year
        self.persistenceService = persistenceService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        definesPresentationContext = true

        persistenceService.performRead(AllTracksOrderedByName()) { result in
            DispatchQueue.main.async { [weak self] in
                switch result {
                case let .failure(error): self?.tracksLoadingDidError(with: error)
                case let .success(tracks): self?.tracksLoadingDidFinish(with: tracks)
                }
            }
        }
    }

    private func tracksLoadingDidError(with error: Error) {
        assertionFailure(error.localizedDescription)
        delegate?.yearControllerDidError(self)
    }

    private func tracksLoadingDidFinish(with tracks: [Track]) {
        self.tracks = tracks

        let tracksViewController = makeTracksViewController()
        addChild(tracksViewController)
        view.addSubview(tracksViewController.view)
        tracksViewController.didMove(toParent: self)
    }
}

extension YearController: TracksViewControllerDataSource, TracksViewControllerDelegate {
    func numberOfSections(in _: TracksViewController) -> Int {
        1
    }

    func sectionIndexTitles(for _: TracksViewController) -> [String]? {
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
        delegate?.yearControllerDidError(self)
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

    func eventsViewController(_ presentingViewController: EventsViewController, didSelect event: Event) {
        let eventViewController = makeEventViewController(for: event)

        if presentingViewController == eventsViewController {
            presentingViewController.showDetailViewController(eventViewController, sender: nil)
        } else if presentingViewController == resultsViewController {
            tracksViewController?.showDetailViewController(eventViewController, sender: nil)
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

                    let emptyFormat = NSLocalizedString("more.search.empty", comment: "")
                    let emptyString = String(format: emptyFormat, query)
                    self?.resultsViewController?.emptyBackgroundText = emptyString
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

    func makeTracksViewController() -> TracksViewController {
        let tracksViewController = TracksViewController()
        tracksViewController.addEmbeddedSearchViewController(makeSearchController())
        tracksViewController.dataSource = self
        tracksViewController.delegate = self
        tracksViewController.title = year
        self.tracksViewController = tracksViewController
        return tracksViewController
    }

    func makeEventsViewController(for track: Track) -> EventsViewController {
        let eventsViewController = EventsViewController(style: .grouped)
        eventsViewController.extendedLayoutIncludesOpaqueBars = true
        eventsViewController.title = track.name
        eventsViewController.dataSource = self
        eventsViewController.delegate = self
        self.eventsViewController = eventsViewController
        return eventsViewController
    }

    func makeEventViewController(for event: Event) -> EventController {
        EventController(event: event)
    }
}
