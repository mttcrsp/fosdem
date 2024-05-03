import Combine
import UIKit

final class YearViewController: TracksViewController {
  typealias Dependencies = HasNavigationService

  var didError: ((YearViewController, Error) -> Void)?
  var results: [Event] = []
  private(set) weak var resultsViewController: EventsViewController?
  private weak var eventsViewController: EventsViewController?
  private var searchController: UISearchController?
  private var cancellables: [AnyCancellable] = []
  private let dependencies: Dependencies
  private let viewModel: YearViewModel
  private let searchViewModel: SearchViewModel

  init(dependencies: Dependencies, viewModel: YearViewModel, searchViewModel: SearchViewModel) {
    self.dependencies = dependencies
    self.viewModel = viewModel
    self.searchViewModel = searchViewModel
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

    let resultsViewController = EventsViewController(style: .grouped)
    resultsViewController.dataSource = self
    resultsViewController.delegate = self
    self.resultsViewController = resultsViewController

    let searchController = UISearchController(searchResultsController: resultsViewController)
    searchController.searchBar.placeholder = L10n.More.Search.prompt
    searchController.searchResultsUpdater = self
    self.searchController = searchController
    addSearchViewController(searchController)

    viewModel.$tracks
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.reloadData()
      }
      .store(in: &cancellables)

    viewModel.$events
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.eventsViewController?.reloadData()
      }
      .store(in: &cancellables)

    viewModel.didFail
      .receive(on: DispatchQueue.main)
      .sink { [weak self] error in
        guard let self else { return }
        didError?(self, error)
      }
      .store(in: &cancellables)

    searchViewModel.$configuration
      .receive(on: DispatchQueue.main)
      .sink { [weak self] configuration in
        self?.resultsViewController?.configure(with: configuration)
        self?.resultsViewController?.reloadData()
      }
      .store(in: &cancellables)

    viewModel.didLoad()
  }
}

extension YearViewController: TracksViewControllerDataSource, TracksViewControllerDelegate {
  func numberOfSections(in _: TracksViewController) -> Int {
    1
  }

  func tracksViewController(_: TracksViewController, numberOfTracksIn _: Int) -> Int {
    viewModel.tracks.count
  }

  func tracksViewController(_: TracksViewController, trackAt indexPath: IndexPath) -> Track {
    viewModel.tracks[indexPath.row]
  }

  func tracksViewController(_ tracksViewController: TracksViewController, didSelect track: Track) {
    viewModel.didSelectTrack(track)
    let eventsViewController = EventsViewController(style: .grouped)
    eventsViewController.title = track.formattedName
    eventsViewController.dataSource = self
    eventsViewController.delegate = self
    self.eventsViewController = eventsViewController
    tracksViewController.show(eventsViewController, sender: nil)
  }
}

extension YearViewController: EventsViewControllerDataSource, EventsViewControllerDelegate {
  func events(in viewController: EventsViewController) -> [Event] {
    switch viewController {
    case eventsViewController: viewModel.events
    case resultsViewController: searchViewModel.configuration.results
    default: []
    }
  }

  func eventsViewController(_: EventsViewController, captionFor event: Event) -> String? {
    event.formattedPeople
  }

  func eventsViewController(_ viewController: EventsViewController, didSelect event: Event) {
    let eventViewController = dependencies.navigationService.makeEventViewController(for: event, options: [])
    show(eventViewController, sender: nil)

    if viewController == resultsViewController {
      viewController.deselectSelectedRow(animated: true)
    }
  }
}

extension YearViewController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    searchViewModel.didChangeQuery(searchController.searchBar.text ?? "")
  }
}
