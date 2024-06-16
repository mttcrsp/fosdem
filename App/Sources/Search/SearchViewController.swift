import Combine
import UIKit

final class SearchViewController: UISplitViewController {
  typealias Dependencies = HasNavigationService

  private(set) weak var resultsViewController: EventsViewController?
  private weak var tracksViewController: TracksViewController?
  private weak var searchController: UISearchController?
  private weak var filtersButton: UIBarButtonItem?
  private var cancellables: [AnyCancellable] = []
  private var tracksConfiguration: TracksConfiguration?
  private let dependencies: Dependencies
  private let viewModel: SearchViewModel
  private let searchViewModel: SearchResultViewModel

  init(dependencies: Dependencies, viewModel: SearchViewModel, searchViewModel: SearchResultViewModel) {
    self.dependencies = dependencies
    self.searchViewModel = searchViewModel
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    delegate = self

    let filtersTitle = L10n.Search.Filter.title
    let filtersAction = #selector(didTapChangeFilter)
    let filtersButton = UIBarButtonItem(title: filtersTitle, style: .plain, target: self, action: filtersAction)
    filtersButton.accessibilityIdentifier = "filters"
    self.filtersButton = filtersButton

    let resultsViewController = EventsViewController(style: .grouped)
    resultsViewController.favoritesDataSource = self
    resultsViewController.favoritesDelegate = self
    resultsViewController.dataSource = self
    resultsViewController.delegate = self
    self.resultsViewController = resultsViewController

    let searchController = UISearchController(searchResultsController: resultsViewController)
    searchController.searchBar.placeholder = L10n.More.Search.prompt
    searchController.searchResultsUpdater = self
    self.searchController = searchController

    let tracksViewController = TracksViewController(style: .insetGrouped)
    tracksViewController.title = L10n.Search.title
    tracksViewController.navigationItem.rightBarButtonItem = filtersButton
    tracksViewController.navigationItem.largeTitleDisplayMode = .always
    tracksViewController.addSearchViewController(searchController)
    tracksViewController.definesPresentationContext = true
    tracksViewController.favoritesDelegate = self
    tracksViewController.dataSource = self
    tracksViewController.delegate = self
    self.tracksViewController = tracksViewController

    let tracksNavigationController = UINavigationController(rootViewController: tracksViewController)
    tracksNavigationController.navigationBar.prefersLargeTitles = true

    viewControllers = [tracksNavigationController]
    if traitCollection.horizontalSizeClass == .regular {
      viewControllers.append(makeWelcomeViewController())
    }

    viewModel.$tracksConfiguration
      .combineLatest(viewModel.$selectedFilter)
      .receive(on: DispatchQueue.main)
      .sink { [weak self, weak tracksViewController] tracksConfiguration, _ in
        guard let self, let tracksViewController else { return }
        self.tracksConfiguration = tracksConfiguration
        tracksViewController.reloadData()
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

extension SearchViewController: UISplitViewControllerDelegate {
  func splitViewController(_: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto _: UIViewController) -> Bool {
    secondaryViewController is WelcomeViewController
  }

  func splitViewController(_: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
    guard let navigationController = primaryViewController as? UINavigationController else { return nil }
    return navigationController.topViewController is TracksViewController ? makeWelcomeViewController() : nil
  }
}

extension SearchViewController: TracksViewControllerDataSource, TracksViewControllerDelegate {
  private var filteredTracks: [Track] {
    tracksConfiguration?.filteredTracks[viewModel.selectedFilter] ?? []
  }

  private var filteredFavoriteTracks: [Track] {
    tracksConfiguration?.filteredFavoriteTracks[viewModel.selectedFilter] ?? []
  }

  func numberOfTracks(in _: TracksViewController) -> Int {
    filteredTracks.count
  }

  func tracksViewController(_: TracksViewController, trackAt index: Int) -> Track {
    filteredTracks[index]
  }

  func numberOfFavoriteTracks(in _: TracksViewController) -> Int {
    filteredFavoriteTracks.count
  }

  func tracksViewController(_: TracksViewController, favoriteTrackAt index: Int) -> Track {
    filteredFavoriteTracks[index]
  }

  func selectedFilter(in _: TracksViewController) -> TracksFilter {
    viewModel.selectedFilter
  }

  func tracksViewController(_ tracksViewController: TracksViewController, didSelect track: Track) {
    let style = traitCollection.userInterfaceIdiom == .pad ? UITableView.Style.insetGrouped : .grouped
    let trackViewController = dependencies.navigationService.makeTrackViewController(for: track, style: style)
    trackViewController.navigationItem.largeTitleDisplayMode = preferredLargeTitleDisplayModeForDetail(withTitle: track.formattedName)
    trackViewController.title = track.formattedName
    trackViewController.didError = { _, _ in
      tracksViewController.navigationController?.popViewController(animated: true)
      tracksViewController.deselectSelectedRow(animated: true)

      let errorViewController = UIAlertController.makeErrorController()
      tracksViewController.present(errorViewController, animated: true)
    }

    let navigationController = UINavigationController(rootViewController: trackViewController)
    tracksViewController.showDetailViewController(navigationController, sender: nil)
    UIAccessibility.post(notification: .screenChanged, argument: navigationController.view)
  }

  private func preferredLargeTitleDisplayModeForDetail(withTitle title: String) -> UINavigationItem.LargeTitleDisplayMode {
    let font = UIFont.fos_preferredFont(forTextStyle: .largeTitle)
    let attributes = [NSAttributedString.Key.font: font]
    let attributedString = NSAttributedString(string: title, attributes: attributes)
    let preferredWidth = attributedString.size().width
    let availableWidth = view.bounds.size.width - view.layoutMargins.left - view.layoutMargins.right - 32
    return preferredWidth < availableWidth ? .always : .never
  }

  @objc private func didTapChangeFilter() {
    let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    alertController.popoverPresentationController?.barButtonItem = filtersButton
    alertController.view.accessibilityIdentifier = "filters"

    let filters = tracksConfiguration?.filters ?? []
    for filter in filters where filter != viewModel.selectedFilter {
      alertController.addAction(
        .init(title: filter.title, style: .default) { [weak self] _ in
          self?.viewModel.didSelectFilter(filter)
        }
      )
    }

    let cancelTitle = L10n.Search.Filter.cancel
    let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel)
    alertController.addAction(cancelAction)

    tracksViewController?.present(alertController, animated: true)
  }
}

extension SearchViewController: TracksViewControllerFavoritesDelegate {
  func tracksViewController(_: TracksViewController, canFavorite track: Track) -> Bool {
    viewModel.canFavorite(track)
  }

  func tracksViewController(_: TracksViewController, didFavorite track: Track) {
    viewModel.didFavorite(track)
  }

  func tracksViewController(_: TracksViewController, didUnfavorite track: Track) {
    viewModel.didUnfavorite(track)
  }
}

extension SearchViewController: EventsViewControllerDataSource, EventsViewControllerDelegate {
  func events(in _: EventsViewController) -> [Event] {
    searchViewModel.configuration.results
  }

  func eventsViewController(_: EventsViewController, captionFor event: Event) -> String? {
    event.formattedTrack
  }

  func eventsViewController(_ eventsViewController: EventsViewController, didSelect event: Event) {
    eventsViewController.deselectSelectedRow(animated: true)

    let eventOptions: EventOptions = [.enableFavoriting, .enableTrackSelection]
    let eventViewController = dependencies.navigationService.makeEventViewController(for: event, options: eventOptions)
    tracksViewController?.showDetailViewController(eventViewController, sender: nil)

    if traitCollection.horizontalSizeClass == .regular {
      searchController?.searchBar.endEditing(true)
    }
  }
}

extension SearchViewController: EventsViewControllerFavoritesDataSource, EventsViewControllerFavoritesDelegate {
  func eventsViewController(_: EventsViewController, canFavorite event: Event) -> Bool {
    viewModel.canFavorite(event)
  }

  func eventsViewController(_: EventsViewController, didFavorite event: Event) {
    viewModel.didFavorite(event)
  }

  func eventsViewController(_: EventsViewController, didUnfavorite event: Event) {
    viewModel.didUnfavorite(event)
  }
}

extension SearchViewController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    searchViewModel.didChangeQuery(searchController.searchBar.text ?? "")
  }
}

extension SearchViewController {
  func popToRootViewController() {
    if traitCollection.horizontalSizeClass == .compact {
      tracksViewController?.navigationController?.popToRootViewController(animated: true)
    }
  }
}

private extension SearchViewController {
  func makeWelcomeViewController() -> WelcomeViewController {
    WelcomeViewController(year: viewModel.year)
  }
}
