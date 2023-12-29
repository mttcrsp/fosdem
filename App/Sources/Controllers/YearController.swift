import UIKit

final class YearController: TracksViewController {
  typealias Dependencies = HasNavigationService

  var didError: ((YearController, Error) -> Void)?

  private(set) weak var resultsViewController: EventsViewController?
  private weak var eventsViewController: EventsViewController?
  private var searchController: UISearchController?

  private var tracks: [Track] = []
  private var events: [Event] = []
  var results: [Event] = []

  private let dependencies: Dependencies
  let persistenceService: PersistenceServiceProtocol

  init(persistenceService: PersistenceServiceProtocol, dependencies: Dependencies) {
    self.dependencies = dependencies
    self.persistenceService = persistenceService
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .systemGroupedBackground

    delegate = self
    dataSource = self
    definesPresentationContext = true
    addSearchViewController(makeSearchController())

    persistenceService.performRead(GetAllTracks()) { result in
      DispatchQueue.main.async { [weak self] in
        switch result {
        case let .failure(error):
          self?.tracksLoadingDidError(with: error)
        case let .success(tracks):
          self?.tracksLoadingDidFinish(with: tracks)
        }
      }
    }
  }

  private func tracksLoadingDidError(with error: Error) {
    didError?(self, error)
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
    persistenceService.performRead(GetEventsByTrack(track: track.name)) { result in
      DispatchQueue.main.async { [weak self] in
        switch result {
        case let .failure(error):
          self?.eventsLoadingDidError(with: error)
        case let .success(events):
          self?.eventsLoadingDidFinish(with: events)
        }
      }
    }
  }

  private func eventsLoadingDidError(with error: Error) {
    assertionFailure(error.localizedDescription)
    didError?(self, error)
  }

  private func eventsLoadingDidFinish(with events: [Event]) {
    self.events = events
    eventsViewController?.reloadData()
  }
}

extension YearController: EventsViewControllerDataSource, EventsViewControllerDelegate {
  func events(in viewController: EventsViewController) -> [Event] {
    switch viewController {
    case eventsViewController:
      return events
    case resultsViewController:
      return results
    default:
      return []
    }
  }

  func eventsViewController(_: EventsViewController, captionFor event: Event) -> String? {
    event.formattedPeople
  }

  func eventsViewController(_ viewController: EventsViewController, didSelect event: Event) {
    let eventViewController = makeEventViewController(for: event)
    show(eventViewController, sender: nil)

    if viewController == resultsViewController {
      viewController.deselectSelectedRow(animated: true)
    }
  }
}

extension YearController: UISearchResultsUpdating, EventsSearchController {
  func updateSearchResults(for searchController: UISearchController) {
    didChangeQuery(searchController.searchBar.text ?? "")
  }
}

private extension YearController {
  func makeSearchController() -> UISearchController {
    let searchController = UISearchController(searchResultsController: makeResultsViewController())
    searchController.searchBar.placeholder = L10n.More.Search.prompt
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
    eventsViewController.title = track.formattedName
    eventsViewController.dataSource = self
    eventsViewController.delegate = self
    self.eventsViewController = eventsViewController
    return eventsViewController
  }

  func makeEventViewController(for event: Event) -> UIViewController {
    dependencies.navigationService.makePastEventViewController(for: event)
  }
}
