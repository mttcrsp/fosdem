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
  private var observer: NSObjectProtocol?

  private let dependencies: Dependencies

  init(dependencies: Dependencies) {
    self.dependencies = dependencies
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func didSelectTab() {
    guard traitCollection.horizontalSizeClass == .compact else { return }

    if let navigationController = tracksViewController?.navigationController, navigationController.viewControllers.count > 1 {
      navigationController.popToRootViewController(animated: true)
    } else {
      searchController?.searchBar.becomeFirstResponder()
    }
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
    tracksViewController.favoritesDataSource = self
    tracksViewController.favoritesDelegate = self
    tracksViewController.indexDataSource = self
    tracksViewController.indexDelegate = self
    tracksViewController.delegate = self
    self.tracksViewController = tracksViewController

    let tracksNavigationController = UINavigationController(rootViewController: tracksViewController)
    tracksNavigationController.navigationBar.prefersLargeTitles = true

    viewControllers = [tracksNavigationController]
    if traitCollection.horizontalSizeClass == .regular {
      viewControllers.append(makeWelcomeViewController())
    }

    reloadTracks(animated: false)
    observer = dependencies.favoritesService.addObserverForTracks { [weak self] in
      self?.reloadTracks(animated: true)
    }
  }

  private func reloadTracks(animated: Bool) {
    dependencies.tracksService.loadConfiguration { [weak self] tracksConfiguration in
      guard let self else { return }
      self.tracksConfiguration = tracksConfiguration
      self.tracksViewController?.setSections(tracksSections, animatingDifferences: animated)
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

extension SearchController: TracksViewControllerDelegate {
  private var filteredTracks: [Track] {
    tracksConfiguration?.filteredTracks[selectedFilter] ?? []
  }

  private var filteredFavoriteTracks: [Track] {
    tracksConfiguration?.filteredFavoriteTracks[selectedFilter] ?? []
  }

  private var hasFavoriteTracks: Bool {
    !filteredFavoriteTracks.isEmpty
  }

  var tracksSections: [TracksSection] {
    var sections: [TracksSection] = []
    if hasFavoriteTracks {
      sections.append(
        .init(
          title: L10n.Search.Filter.favorites,
          accessibilityIdentifier: "favorites",
          tracks: filteredFavoriteTracks
        )
      )
    }
    sections.append(
      .init(
        title: selectedFilter.title,
        accessibilityIdentifier: selectedFilter.accessibilityIdentifier,
        tracks: filteredTracks
      )
    )
    return sections
  }

  func tracksViewController(_ tracksViewController: TracksViewController, didSelect track: Track) {
    let style = traitCollection.userInterfaceIdiom == .pad ? UITableView.Style.insetGrouped : .grouped
    let trackViewController = dependencies.navigationService.makeTrackViewController(for: track, style: style)
    trackViewController.navigationItem.largeTitleDisplayMode = preferredLargeTitleDisplayModeForDetail(withTitle: track.formattedName)
    trackViewController.title = track.formattedName
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
    for filter in filters where filter != selectedFilter {
      let actionHandler: (UIAlertAction) -> Void = { [weak self] _ in
        guard let self else { return }
        self.selectedFilter = filter
        self.tracksViewController?.setSections(tracksSections, animatingDifferences: false)
      }
      let action = UIAlertAction(title: filter.title, style: .default, handler: actionHandler)
      alertController.addAction(action)
    }

    let cancelTitle = L10n.Search.Filter.cancel
    let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel)
    alertController.addAction(cancelAction)

    tracksViewController?.present(alertController, animated: true)
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

extension SearchController: EventsViewControllerDelegate {
  func eventsViewController(_: EventsViewController, captionFor event: Event) -> String? {
    event.formattedTrack
  }

  func eventsViewController(_ eventsViewController: EventsViewController, didSelect event: Event) {
    eventsViewController.deselectSelectedRow(animated: true)

    let eventViewController = dependencies.navigationService.makeEventViewController(for: event)
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
  var persistenceService: PersistenceServiceProtocol {
    dependencies.persistenceService
  }

  func updateSearchResults(for searchController: UISearchController) {
    didChangeQuery(searchController.searchBar.text ?? "")
  }
}

private extension SearchController {
  func makeWelcomeViewController() -> WelcomeViewController {
    WelcomeViewController(year: type(of: dependencies.yearsService).current)
  }
}
