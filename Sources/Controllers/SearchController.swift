import UIKit

final class SearchController: UISplitViewController {
  private weak var resultsViewController: EventsViewController?
  private weak var tracksViewController: TracksViewController?
  private weak var eventsViewController: EventsViewController?
  private weak var searchController: UISearchController?
  private weak var filtersButton: UIBarButtonItem?

  private var captions: [Event: String] = [:]
  private var events: [Event] = []

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

  private var tracksService: TracksService {
    services.tracksService
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

    delegate = self

    tracksService.delegate = self
    tracksService.loadTracks()

    let tracksViewController = makeTracksViewController()
    let tracksNavigationController = UINavigationController(rootViewController: tracksViewController)
    tracksNavigationController.navigationBar.prefersLargeTitles = true

    viewControllers = [tracksNavigationController]
    if traitCollection.horizontalSizeClass == .regular {
      viewControllers.append(WelcomeViewController())
    }
  }

  private func prefersLargeTitleForDetailViewController(withTitle title: String) -> Bool {
    let font = UIFont.fos_preferredFont(forTextStyle: .largeTitle)
    let attributes = [NSAttributedString.Key.font: font]
    let attributedString = NSAttributedString(string: title, attributes: attributes)
    let preferredWidth = attributedString.size().width
    let availableWidth = view.bounds.size.width - view.layoutMargins.left - view.layoutMargins.right - 32
    return preferredWidth < availableWidth
  }
}

extension SearchController: UISplitViewControllerDelegate {
  func splitViewController(_: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto _: UIViewController) -> Bool {
    secondaryViewController is WelcomeViewController
  }

  func splitViewController(_: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
    primaryViewController is TracksViewController ? WelcomeViewController() : nil
  }
}

extension SearchController: TracksServiceDelegate {
  func tracksServiceDidUpdate(_: TracksService) {
    tracksViewController?.reloadData()
  }
}

extension SearchController: TracksViewControllerDataSource, TracksViewControllerDelegate {
  private var filteredTracks: [Track] {
    tracksService.filteredTracks[selectedFilter] ?? []
  }

  private var filteredFavoriteTracks: [Track] {
    tracksService.filteredFavoriteTracks[selectedFilter] ?? []
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
      return NSLocalizedString("search.filter.favorites", comment: "")
    } else {
      return selectedFilter.title
    }
  }

  func tracksViewController(_: TracksViewController, numberOfTracksIn section: Int) -> Int {
    if isFavoriteSection(section) {
      return filteredFavoriteTracks.count
    } else {
      return filteredTracks.count
    }
  }

  func tracksViewController(_: TracksViewController, trackAt indexPath: IndexPath) -> Track {
    if isFavoriteSection(indexPath.section) {
      return filteredFavoriteTracks[indexPath.row]
    } else {
      return filteredTracks[indexPath.row]
    }
  }

  func tracksViewController(_ tracksViewController: TracksViewController, didSelect track: Track) {
    persistenceService.performRead(EventsForTrack(track: track.name)) { [weak tracksViewController] result in
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }

        switch result {
        case .failure:
          let errorViewController = UIAlertController.makeErrorController()
          tracksViewController?.present(errorViewController, animated: true)
          tracksViewController?.deselectSelectedRow(animated: true)
        case let .success(events):
          self.events = events
          self.selectedTrack = track
          self.captions = events.captions

          let eventsViewController = self.makeEventsViewController(for: track)
          let eventsNavigationController = UINavigationController(rootViewController: eventsViewController)
          tracksViewController?.showDetailViewController(eventsNavigationController, sender: nil)
        }
      }
    }
  }

  @objc private func didTapChangeFilter() {
    let filtersViewController = makeFiltersViewController(with: tracksService.filters, selectedFilter: selectedFilter)
    tracksViewController?.present(filtersViewController, animated: true)
  }

  private func didSelectFilter(_ filter: TracksFilter) {
    selectedFilter = filter
    tracksViewController?.reloadData()
  }
}

extension SearchController: TracksViewControllerIndexDataSource, TracksViewControllerIndexDelegate {
  func sectionIndexTitles(in _: TracksViewController) -> [String] {
    if let sectionIndexTitles = tracksService.filteredIndexTitles[selectedFilter] {
      return sectionIndexTitles.keys.sorted()
    } else {
      return []
    }
  }

  func tracksViewController(_ tracksViewController: TracksViewController, didSelect section: Int) {
    let titles = sectionIndexTitles(in: tracksViewController)
    let title = titles[section]

    if let index = tracksService.filteredIndexTitles[selectedFilter]?[title] {
      let indexPath = IndexPath(row: index, section: hasFavoriteTracks ? 1 : 0)
      tracksViewController.scrollToRow(at: indexPath, at: .top, animated: false)
    }
  }
}

extension SearchController: TracksViewControllerFavoritesDataSource, TracksViewControllerFavoritesDelegate {
  func tracksViewController(_: TracksViewController, canFavorite track: Track) -> Bool {
    !favoritesService.contains(track)
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

  func eventsViewController(_ viewController: EventsViewController, captionFor event: Event) -> String? {
    switch viewController {
    case eventsViewController:
      return captions[event]
    case resultsViewController:
      return event.track
    default:
      return nil
    }
  }

  func eventsViewController(_ viewController: EventsViewController, didSelect event: Event) {
    switch viewController {
    case eventsViewController:
      trackViewController(viewController, didSelect: event)
    case resultsViewController:
      resultsViewController(viewController, didSelect: event)
    default:
      break
    }
  }

  private func trackViewController(_ trackViewController: EventsViewController, didSelect event: Event) {
    let eventViewController = makeEventViewController(for: event)
    trackViewController.show(eventViewController, sender: nil)
  }

  private func resultsViewController(_ eventsViewController: EventsViewController, didSelect event: Event) {
    eventsViewController.deselectSelectedRow(animated: true)

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
      events = []
      resultsViewController?.emptyBackgroundMessage = nil
      resultsViewController?.emptyBackgroundTitle = nil
      resultsViewController?.view.isHidden = true
      resultsViewController?.reloadData()
      return
    }

    let operation = EventsForSearch(query: query)
    services.persistenceService.performRead(operation) { [weak self] result in
      DispatchQueue.main.async {
        switch result {
        case .failure:
          let errorTitle = NSLocalizedString("search.error.title", comment: "")
          let errorMessage = NSLocalizedString("search.error.message", comment: "")
          self?.events = []
          self?.resultsViewController?.emptyBackgroundMessage = errorMessage
          self?.resultsViewController?.emptyBackgroundTitle = errorTitle
          self?.resultsViewController?.view.isHidden = false
          self?.resultsViewController?.reloadData()
        case let .success(events):
          let emptyTitle = NSLocalizedString("search.empty.title", comment: "")
          let emptyMessageFormat = NSLocalizedString("search.empty.message", comment: "")
          let emptyMessage = String(format: emptyMessageFormat, query)
          self?.events = events
          self?.resultsViewController?.emptyBackgroundMessage = emptyMessage
          self?.resultsViewController?.emptyBackgroundTitle = emptyTitle
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
    self.filtersButton = filtersButton

    let tracksViewController = TracksViewController(style: .fos_insetGrouped)
    tracksViewController.title = NSLocalizedString("search.title", comment: "")
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
    let resultsViewController = EventsViewController(style: .grouped)
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

    let style: UITableView.Style
    if traitCollection.userInterfaceIdiom == .pad {
      style = .fos_insetGrouped
    } else {
      style = .grouped
    }

    let eventsViewController = EventsViewController(style: style)
    eventsViewController.navigationItem.rightBarButtonItem = favoriteButton
    eventsViewController.favoritesDataSource = self
    eventsViewController.favoritesDelegate = self
    eventsViewController.title = track.name
    eventsViewController.dataSource = self
    eventsViewController.delegate = self
    self.eventsViewController = eventsViewController

    if prefersLargeTitleForDetailViewController(withTitle: track.name) {
      eventsViewController.navigationItem.largeTitleDisplayMode = .always
    } else {
      eventsViewController.navigationItem.largeTitleDisplayMode = .never
    }

    observation = favoritesService.addObserverForTracks { [weak favoriteButton, weak self] in
      favoriteButton?.title = self?.favoriteTitle
    }

    return eventsViewController
  }

  func makeEventViewController(for event: Event) -> EventController {
    EventController(event: event, services: services)
  }
}

private extension Array where Element == Event {
  var captions: [Event: String] {
    var result: [Event: String] = [:]

    if let event = first, let caption = event.formattedStartWithWeekday {
      result[event] = caption
    }

    for (lhs, rhs) in zip(self, dropFirst()) {
      if lhs.isSameWeekday(as: rhs) {
        if let caption = rhs.formattedStart {
          result[rhs] = caption
        }
      } else {
        if let caption = rhs.formattedStartWithWeekday {
          result[rhs] = caption
        }
      }
    }

    return result
  }
}
