import UIKit

final class SearchController: UISplitViewController {
  typealias Dependencies = HasFavoritesService & HasNavigationService & HasPersistenceService & HasTracksService & HasYearsService

  private(set) weak var resultsViewController: EventsViewController?
  private weak var tracksViewController: TracksViewController?
  private weak var searchController: UISearchController?
  private weak var filtersButton: UIBarButtonItem?

  var results: [Event] = []

  private var selectedFilter: TracksFilter = .all
  private var tracksConfiguration: TracksConfiguration?
  private var observers: [NSObjectProtocol] = []

  private let dependencies: Dependencies

  init(dependencies: Dependencies) {
    self.dependencies = dependencies
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  var persistenceService: PersistenceServiceProtocol {
    dependencies.persistenceService
  }

  func popToRootViewController() {
    if traitCollection.horizontalSizeClass == .compact {
      tracksViewController?.navigationController?.popToRootViewController(animated: true)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    delegate = self

    reloadTracks()
    observers = [
      dependencies.favoritesService.addObserverForTracks { [weak self] in
        self?.reloadTracks()
      },
    ]

    let tracksViewController = makeTracksViewController()
    let tracksNavigationController = UINavigationController(rootViewController: tracksViewController)
    tracksNavigationController.navigationBar.prefersLargeTitles = true

    viewControllers = [tracksNavigationController]
    if traitCollection.horizontalSizeClass == .regular {
      viewControllers.append(makeWelcomeViewController())
    }
  }

  private func reloadTracks() {
    dependencies.tracksService.loadConfiguration { [weak self] tracksConfiguration in
      self?.tracksLoadingDidSucceed(tracksConfiguration)
    }
  }

  private func tracksLoadingDidSucceed(_ tracksConfiguration: TracksConfiguration) {
    guard let currentTracksConfiguration = self.tracksConfiguration else {
      self.tracksConfiguration = tracksConfiguration
      tracksViewController?.reloadData()
      return
    }

    let oldNonFavoriteTracks = currentTracksConfiguration.filteredTracks[selectedFilter]?.map(\.name) ?? []
    let newNonFavoriteTracks = tracksConfiguration.filteredTracks[selectedFilter]?.map(\.name) ?? []
    guard oldNonFavoriteTracks == newNonFavoriteTracks else {
      self.tracksConfiguration = tracksConfiguration
      tracksViewController?.reloadData()
      return
    }

    var oldIdentifiers = currentTracksConfiguration.filteredFavoriteTracks[selectedFilter]?.map(\.name) ?? []
    let newIdentifiers = tracksConfiguration.filteredFavoriteTracks[selectedFilter]?.map(\.name) ?? []
    let deletesIdentifiers = Set(oldIdentifiers).subtracting(Set(newIdentifiers))
    let insertsIdentifiers = Set(newIdentifiers).subtracting(Set(oldIdentifiers))

    tracksViewController?.performBatchUpdates {
      switch (oldIdentifiers.isEmpty, newIdentifiers.isEmpty) {
      case (true, false):
        tracksViewController?.insertFavoritesSection()
      case (false, true):
        tracksViewController?.deleteFavoritesSection()
      default:
        break
      }

      for (index, track) in oldIdentifiers.enumerated().reversed() where deletesIdentifiers.contains(track) {
        tracksViewController?.deleteFavorite(at: index)
        oldIdentifiers.remove(at: index)
      }

      for (index, track) in newIdentifiers.enumerated() where insertsIdentifiers.contains(track) {
        tracksViewController?.insertFavorite(at: index)
        oldIdentifiers.insert(track, at: index)
      }

      self.tracksConfiguration = tracksConfiguration
    }
  }
}

extension SearchController: UISplitViewControllerDelegate {
  func splitViewController(_: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto _: UIViewController) -> Bool {
    secondaryViewController is WelcomeViewController
  }

  func splitViewController(_: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
    guard let navigationController = primaryViewController as? UINavigationController else { return nil }
    return navigationController.topViewController is TracksViewController ? makeWelcomeViewController() : nil
  }
}

extension SearchController: TracksViewControllerDataSource, TracksViewControllerDelegate {
  private var filteredTracks: [Track] {
    tracksConfiguration?.filteredTracks[selectedFilter] ?? []
  }

  private var filteredFavoriteTracks: [Track] {
    tracksConfiguration?.filteredFavoriteTracks[selectedFilter] ?? []
  }

  private var hasFavoriteTracks: Bool {
    !filteredFavoriteTracks.isEmpty
  }

  private func isFavoriteSection(_ section: Int) -> Bool {
    section == 0 && hasFavoriteTracks
  }

  func numberOfSections(in _: TracksViewController) -> Int {
    hasFavoriteTracks ? 2 : 1
  }

  func tracksViewController(_: TracksViewController, titleForSectionAt section: Int) -> String? {
    if isFavoriteSection(section) {
      L10n.Search.Filter.favorites
    } else {
      selectedFilter.title
    }
  }

  func tracksViewController(_: TracksViewController, accessibilityIdentifierForSectionAt section: Int) -> String? {
    if isFavoriteSection(section) {
      "favorites"
    } else {
      selectedFilter.accessibilityIdentifier
    }
  }

  func tracksViewController(_: TracksViewController, numberOfTracksIn section: Int) -> Int {
    if isFavoriteSection(section) {
      filteredFavoriteTracks.count
    } else {
      filteredTracks.count
    }
  }

  func tracksViewController(_: TracksViewController, trackAt indexPath: IndexPath) -> Track {
    if isFavoriteSection(indexPath.section) {
      filteredFavoriteTracks[indexPath.row]
    } else {
      filteredTracks[indexPath.row]
    }
  }

  func tracksViewController(_ tracksViewController: TracksViewController, didSelect track: Track) {
    let style = traitCollection.userInterfaceIdiom == .pad ? UITableView.Style.insetGrouped : .grouped
    let trackViewController = dependencies.navigationService.makeTrackViewController(for: track, style: style)
    trackViewController.load { error in
      if error != nil {
        let errorViewController = UIAlertController.makeErrorController()
        tracksViewController.present(errorViewController, animated: true)
        tracksViewController.deselectSelectedRow(animated: true)
      } else {
        let navigationController = UINavigationController(rootViewController: trackViewController)
        tracksViewController.showDetailViewController(navigationController, sender: nil)
        UIAccessibility.post(notification: .screenChanged, argument: navigationController.view)
      }
    }
  }

  @objc private func didTapChangeFilter() {
    let filters = tracksConfiguration?.filters ?? []
    let filtersViewController = makeFiltersViewController(with: filters, selectedFilter: selectedFilter)
    tracksViewController?.present(filtersViewController, animated: true)
  }

  private func didSelectFilter(_ filter: TracksFilter) {
    selectedFilter = filter
    tracksViewController?.reloadData()
  }
}

extension SearchController: TracksViewControllerIndexDataSource, TracksViewControllerIndexDelegate {
  func sectionIndexTitles(in _: TracksViewController) -> [String] {
    if let sectionIndexTitles = tracksConfiguration?.filteredIndexTitles[selectedFilter] {
      sectionIndexTitles.keys.sorted()
    } else {
      []
    }
  }

  func tracksViewController(_ tracksViewController: TracksViewController, didSelect section: Int) {
    let titles = sectionIndexTitles(in: tracksViewController)
    let title = titles[section]

    if let index = tracksConfiguration?.filteredIndexTitles[selectedFilter]?[title] {
      let indexPath = IndexPath(row: index, section: hasFavoriteTracks ? 1 : 0)
      tracksViewController.scrollToRow(at: indexPath, at: .top, animated: false)
    }
  }
}

extension SearchController: TracksViewControllerFavoritesDataSource, TracksViewControllerFavoritesDelegate {
  func tracksViewController(_: TracksViewController, canFavorite track: Track) -> Bool {
    !dependencies.favoritesService.contains(track)
  }

  func tracksViewController(_: TracksViewController, didFavorite track: Track) {
    dependencies.favoritesService.addTrack(withIdentifier: track.name)
  }

  func tracksViewController(_: TracksViewController, didUnfavorite track: Track) {
    dependencies.favoritesService.removeTrack(withIdentifier: track.name)
  }
}

extension SearchController: EventsViewControllerDataSource, EventsViewControllerDelegate {
  func events(in _: EventsViewController) -> [Event] {
    results
  }

  func eventsViewController(_: EventsViewController, captionFor event: Event) -> String? {
    event.formattedTrack
  }

  func eventsViewController(_ eventsViewController: EventsViewController, didSelect event: Event) {
    eventsViewController.deselectSelectedRow(animated: true)

    let eventViewController = makeEventViewController(for: event)
    tracksViewController?.showDetailViewController(eventViewController, sender: nil)

    if traitCollection.horizontalSizeClass == .regular {
      searchController?.searchBar.endEditing(true)
    }
  }
}

extension SearchController: EventsViewControllerFavoritesDataSource, EventsViewControllerFavoritesDelegate {
  func eventsViewController(_: EventsViewController, canFavorite event: Event) -> Bool {
    !dependencies.favoritesService.contains(event)
  }

  func eventsViewController(_: EventsViewController, didFavorite event: Event) {
    dependencies.favoritesService.addEvent(withIdentifier: event.id)
  }

  func eventsViewController(_: EventsViewController, didUnfavorite event: Event) {
    dependencies.favoritesService.removeEvent(withIdentifier: event.id)
  }
}

extension SearchController: UISearchResultsUpdating, EventsSearchController {
  func updateSearchResults(for searchController: UISearchController) {
    didChangeQuery(searchController.searchBar.text ?? "")
  }
}

private extension SearchController {
  func makeTracksViewController() -> TracksViewController {
    let filtersTitle = L10n.Search.Filter.title
    let filtersAction = #selector(didTapChangeFilter)
    let filtersButton = UIBarButtonItem(title: filtersTitle, style: .plain, target: self, action: filtersAction)
    filtersButton.accessibilityIdentifier = "filters"
    self.filtersButton = filtersButton

    let tracksViewController = TracksViewController(style: .insetGrouped)
    tracksViewController.title = L10n.Search.title
    tracksViewController.navigationItem.rightBarButtonItem = filtersButton
    tracksViewController.navigationItem.largeTitleDisplayMode = .always
    tracksViewController.addSearchViewController(makeSearchController())
    tracksViewController.definesPresentationContext = true
    tracksViewController.favoritesDataSource = self
    tracksViewController.favoritesDelegate = self
    tracksViewController.indexDataSource = self
    tracksViewController.indexDelegate = self
    tracksViewController.dataSource = self
    tracksViewController.delegate = self
    self.tracksViewController = tracksViewController
    return tracksViewController
  }

  func makeFiltersViewController(with filters: [TracksFilter], selectedFilter: TracksFilter) -> UIAlertController {
    let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    alertController.popoverPresentationController?.barButtonItem = filtersButton
    alertController.view.accessibilityIdentifier = "filters"

    for filter in filters where filter != selectedFilter {
      let actionHandler: (UIAlertAction) -> Void = { [weak self] _ in self?.didSelectFilter(filter) }
      let action = UIAlertAction(title: filter.title, style: .default, handler: actionHandler)
      alertController.addAction(action)
    }

    let cancelTitle = L10n.Search.Filter.cancel
    let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel)
    alertController.addAction(cancelAction)

    return alertController
  }

  func makeSearchController() -> UISearchController {
    let searchController = UISearchController(searchResultsController: makeResultsViewController())
    searchController.searchBar.placeholder = L10n.More.Search.prompt
    searchController.searchResultsUpdater = self
    self.searchController = searchController
    return searchController
  }

  func makeResultsViewController() -> EventsViewController {
    let resultsViewController = EventsViewController(style: .grouped)
    resultsViewController.favoritesDataSource = self
    resultsViewController.favoritesDelegate = self
    resultsViewController.dataSource = self
    resultsViewController.delegate = self
    self.resultsViewController = resultsViewController
    return resultsViewController
  }

  func makeWelcomeViewController() -> WelcomeViewController {
    WelcomeViewController(year: type(of: dependencies.yearsService).current)
  }

  func makeEventViewController(for event: Event) -> UIViewController {
    dependencies.navigationService.makeEventViewController(for: event)
  }
}
