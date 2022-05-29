import RIBs
import UIKit

typealias ScheduleDependency = HasFavoritesService
  & HasPersistenceService
  & HasTracksService
  & HasYearsService

protocol ScheduleBuildable: Buildable {
  func build() -> ScheduleRouting
}

final class ScheduleBuilder: Builder<ScheduleDependency>, ScheduleBuildable {
  func build() -> ScheduleRouting {
    let viewController = ScheduleViewController()
    let interactor = ScheduleInteractor(presenter: viewController, dependency: dependency)
    let router = ScheduleRouter(interactor: interactor, viewController: viewController)
    viewController.listener = interactor
    return router
  }
}

protocol ScheduleRouting: ViewableRouting {}

final class ScheduleRouter: ViewableRouter<ScheduleInteractable, ScheduleViewControllable>, ScheduleRouting {
  override init(interactor: ScheduleInteractable, viewController: ScheduleViewControllable) {
    super.init(interactor: interactor, viewController: viewController)
    interactor.router = self
  }
}

protocol ScheduleInteractable: Interactable {
  var router: ScheduleRouting? { get set }
}

final class ScheduleInteractor: PresentableInteractor<SchedulePresentable>, ScheduleInteractable {
  weak var router: ScheduleRouting?

  private var observer: NSObjectProtocol?
  private var selectedFilter: TracksFilter = .all

  private let dependency: ScheduleDependency

  init(presenter: SchedulePresentable, dependency: ScheduleDependency) {
    self.dependency = dependency
    super.init(presenter: presenter)
  }

  override func didBecomeActive() {
    super.didBecomeActive()

    presenter.year = type(of: dependency.yearsService).current
    
    dependency.tracksService.delegate = self
    dependency.tracksService.loadTracks()

    observer = dependency.favoritesService.addObserverForTracks { [weak self] _ in
      _ = self
      // self?.presenter.showsFavorite =
    }
  }

  override func willResignActive() {
    super.willResignActive()

    if let observer = observer {
      dependency.favoritesService.removeObserver(observer)
    }
  }
}

extension ScheduleInteractor: SchedulePresentableListener {
  func didFavorite(_ event: Event) {
    dependency.favoritesService.addEvent(withIdentifier: event.id)
  }

  func didFavorite(_ track: Track) {
    dependency.favoritesService.addTrack(withIdentifier: track.name)
  }

  
  func didUnfavorite(_ event: Event) {
    dependency.favoritesService.removeEvent(withIdentifier: event.id)
  }

  func didUnfavorite(_ track: Track) {
    dependency.favoritesService.removeTrack(withIdentifier: track.name)
  }
  
  func canFavoritEvent(_ event: Event) -> Bool {
    !dependency.favoritesService.contains(event)
  }

  func canFavoritEvent(_ track: Track) -> Bool {
    !dependency.favoritesService.contains(track)
  }
  
  func didToggleFavorite(_ track: Track) {
    if dependency.favoritesService.contains(track) {
      dependency.favoritesService.removeTrack(withIdentifier: track.name)
    } else {
      dependency.favoritesService.addTrack(withIdentifier: track.name)
    }
  }

  func didSelectFilters() {
    presenter.showFilters(dependency.tracksService.filters, selectedFilter: selectedFilter)
  }

  func didSelect(_ event: Event) {
    _ = event
  }
  
  func didSelect(_ selectedFilter: TracksFilter) {
    self.selectedFilter = selectedFilter
    presenter.reloadData()
  }
  
  func didSelect(_ track: Track) {
    let operation = EventsForTrack(track: track.name)
    dependency.persistenceService.performRead(operation) { [weak self] result in
      DispatchQueue.main.async { [weak self] in
        switch result {
        case .failure:
          self?.presenter.showError()
        case let .success(events):
          self?.presenter.showEvents(events, for: track)
        }
      }
    }
  }
  
  func didSelectTracksSection(_ section: String) {
    if let index = dependency.tracksService.filteredIndexTitles[selectedFilter]?[section] {
      let indexPath = IndexPath(row: index, section: hasFavoriteTracks ? 1 : 0)
      presenter.scrollToRow(at: indexPath)
    }
  }
}

extension ScheduleInteractor: TracksServiceDelegate {
  func tracksServiceDidUpdateTracks(_: TracksService) {
    presenter.tracksSectionIndexTitles = filteredTracksSectionIndexTitles
    presenter.reloadData()
  }

  func tracksService(_: TracksService, performBatchUpdates updates: () -> Void) {
    presenter.tracksSectionIndexTitles = filteredTracksSectionIndexTitles
    presenter.performBatchUpdates(updates)
  }

  func tracksService(_: TracksService, insertFavoriteWith identifier: String) {
    if filteredFavoriteTracks.count == 1 {
      presenter.insertFavoritesSection()
    } else if let index = filteredFavoriteTracks.firstIndex(where: { track in track.name == identifier }) {
      presenter.insertFavorite(at: index)
    }
  }

  func tracksService(_: TracksService, deleteFavoriteWith identifier: String) {
    if filteredFavoriteTracks.count == 1 {
      presenter.deleteFavoritesSection()
    } else if let index = filteredFavoriteTracks.firstIndex(where: { track in track.name == identifier }) {
      presenter.deleteFavorite(at: index)
    }
  }

  private func isFavoriteSection(_ section: Int) -> Bool {
    section == 0 && hasFavoriteTracks
  }
  
  private var hasFavoriteTracks: Bool {
    !filteredFavoriteTracks.isEmpty
  }
  
  private var filteredTracks: [Track] {
    dependency.tracksService.filteredTracks[selectedFilter] ?? []
  }

  private var filteredFavoriteTracks: [Track] {
    dependency.tracksService.filteredFavoriteTracks[selectedFilter] ?? []
  }
  
  private var filteredTracksSectionIndexTitles: [String] {
    dependency.tracksService.filteredIndexTitles[selectedFilter]?.keys.sorted() ?? []
  }
}

protocol ScheduleViewControllable: ViewControllable {}

protocol SchedulePresentable: Presentable {
  var year: Year? { get set }
  var tracksSectionIndexTitles: [String] { get set }

  func reloadData()
  func performBatchUpdates(_ updates: () -> Void)
  func insertFavoritesSection()
  func deleteFavoritesSection()
  func insertFavorite(at index: Int)
  func deleteFavorite(at index: Int)
  func scrollToRow(at indexPath: IndexPath)
  
  func showError()
  func showEvents(_ events: [Event], for track: Track)
  func showFilters(_ filters: [TracksFilter], selectedFilter: TracksFilter)
}

protocol SchedulePresentableListener: AnyObject {
  func didFavorite(_ event: Event)
  func didUnfavorite(_ event: Event)
  func canFavoritEvent(_ event: Event) -> Bool
  
  func didFavorite(_ track: Track)
  func didUnfavorite(_ track: Track)
  func canFavoritEvent(_ track: Track) -> Bool

  func didSelectFilters()
  func didSelect(_ filter: TracksFilter)
  func didSelect(_ event: Event)
  func didSelect(_ track: Track)
  func didSelectTracksSection(_ section: String)
}

final class ScheduleViewController: UISplitViewController, ScheduleViewControllable {
  weak var listener: SchedulePresentableListener?

  var showsFavorite = false {
    didSet {
      favoriteButton.title = showsFavorite ? L10n.unfavorite : L10n.favorite
      favoriteButton.accessibilityIdentifier = showsFavorite ? "unfavorite" : "favorite"
    }
  }

  var tracksSectionIndexTitles: [String] = []
  var year: Year?

  private var events: [Event] = []
  private var eventsCaptions: [Event: String] = [:]
  
  private weak var tracksViewController: TracksViewController?
  private weak var eventsViewController: EventsViewController?
  private weak var filtersButton: UIBarButtonItem?

  private lazy var favoriteButton: UIBarButtonItem = {
    let favoriteAction = #selector(didToggleFavorite)
    let favoriteButton = UIBarButtonItem(title: nil, style: .plain, target: self, action: favoriteAction)
    return favoriteButton
  }()
}

extension ScheduleViewController {
  override func viewDidLoad() {
    super.viewDidLoad()

    delegate = self
    maximumPrimaryColumnWidth = 375
    preferredPrimaryColumnWidthFraction = 0.4

    let tracksViewController = makeTracksViewController()
    let tracksNavigationController = UINavigationController(rootViewController: tracksViewController)
    tracksNavigationController.navigationBar.prefersLargeTitles = true

    viewControllers = [tracksNavigationController]
    if traitCollection.horizontalSizeClass == .regular {
      viewControllers.append(makeWelcomeViewController())
    }
  }

  @objc private func didToggleFavorite() {
//    guard let selectedTrack = selectedTrack else { return }
  }

  @objc private func didTapChangeFilter() {
    listener?.didSelectFilters()
  }

  private func didSelectFilter(_ filter: TracksFilter) {
    listener?.didSelect(filter)
  }
}

extension ScheduleViewController: SchedulePresentable {
  func reloadData() {
    tracksViewController?.reloadData()
  }

  func performBatchUpdates(_ updates: () -> Void) {
    tracksViewController?.performBatchUpdates(updates)
  }

  func insertFavoritesSection() {
    tracksViewController?.insertFavoritesSection()
  }

  func deleteFavoritesSection() {
    tracksViewController?.deleteFavoritesSection()
  }

  func insertFavorite(at index: Int) {
    tracksViewController?.insertFavorite(at: index)
  }

  func deleteFavorite(at index: Int) {
    tracksViewController?.deleteFavorite(at: index)
  }

  func scrollToRow(at indexPath: IndexPath) {
    tracksViewController?.scrollToRow(at: indexPath, at: .top, animated: false)
  }
  
  func showError() {
    let errorViewController = UIAlertController.makeErrorController()
    tracksViewController?.present(errorViewController, animated: true)
    tracksViewController?.deselectSelectedRow(animated: true)
  }
  
  func showEvents(_ events: [Event], for track: Track) {
    self.events = events
    self.eventsCaptions = events.captions

    let eventsViewController = self.makeEventsViewController(for: track)
    let navigationController = UINavigationController(rootViewController: eventsViewController)
    tracksViewController?.showDetailViewController(navigationController, sender: nil)
    UIAccessibility.post(notification: .screenChanged, argument: navigationController.view)
  }

  func showFilters(_ filters: [TracksFilter], selectedFilter: TracksFilter) {
    let filtersViewController = makeFiltersViewController(with: filters, selectedFilter: selectedFilter)
    tracksViewController?.present(filtersViewController, animated: true)
  }
}

extension ScheduleViewController: UISplitViewControllerDelegate {
  func splitViewController(_: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto _: UIViewController) -> Bool {
    secondaryViewController is WelcomeViewController
  }

  func splitViewController(_: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
    guard let navigationController = primaryViewController as? UINavigationController else { return nil }
    return navigationController.topViewController is TracksViewController ? makeWelcomeViewController() : nil
  }
}

extension ScheduleViewController: TracksViewControllerDataSource {
  func numberOfSections(in tracksViewController: TracksViewController) -> Int {
    <#code#>
  }
  
  func tracksViewController(_ tracksViewController: TracksViewController, numberOfTracksIn section: Int) -> Int {
    <#code#>
  }
  
  func tracksViewController(_ tracksViewController: TracksViewController, trackAt indexPath: IndexPath) -> Track {
    <#code#>
  }
  
  func tracksViewController(_ tracksViewController: TracksViewController, titleForSectionAt section: Int) -> String? {
    <#code#>
  }
  
  func tracksViewController(_ tracksViewController: TracksViewController, accessibilityIdentifierForSectionAt section: Int) -> String? {
    <#code#>
  }
}

extension ScheduleViewController: TracksViewControllerDelegate {
  func tracksViewController(_ tracksViewController: TracksViewController, didSelect track: Track) {
    listener?.didSelect(track)
  }
}

extension ScheduleViewController: TracksViewControllerFavoritesDataSource {
  func tracksViewController(_ tracksViewController: TracksViewController, canFavorite track: Track) -> Bool {
    listener?.canFavoritEvent(track) ?? false
  }
  
  
}

extension ScheduleViewController: TracksViewControllerFavoritesDelegate {
  func tracksViewController(_ tracksViewController: TracksViewController, didFavorite track: Track) {
    listener?.didFavorite(track)
  }
  
  func tracksViewController(_ tracksViewController: TracksViewController, didUnfavorite track: Track) {
    listener?.didUnfavorite(track)
  }
}

extension ScheduleViewController: TracksViewControllerIndexDataSource {
  func sectionIndexTitles(in tracksViewController: TracksViewController) -> [String] {
    tracksSectionIndexTitles
  }
}


extension ScheduleViewController: TracksViewControllerIndexDelegate {
  func tracksViewController(_ tracksViewController: TracksViewController, didSelect section: Int) {
    listener?.didSelectTracksSection(tracksSectionIndexTitles[section])
  }
}

extension ScheduleViewController: EventsViewControllerDataSource {
  func events(in _: EventsViewController) -> [Event] {
    events
  }

  func eventsViewController(_: EventsViewController, captionFor event: Event) -> String? {
    eventsCaptions[event]
  }
}

extension ScheduleViewController: EventsViewControllerDelegate {
  func eventsViewController(_: EventsViewController, didSelect event: Event) {
    listener?.didSelect(event)
  }
}

extension ScheduleViewController: EventsViewControllerFavoritesDataSource {
  func eventsViewController(_: EventsViewController, canFavorite event: Event) -> Bool {
    listener?.canFavoritEvent(event) ?? false
  }
}

extension ScheduleViewController: EventsViewControllerFavoritesDelegate {
  func eventsViewController(_: EventsViewController, didFavorite event: Event) {
    listener?.didFavorite(event)
  }

  func eventsViewController(_: EventsViewController, didUnfavorite event: Event) {
    listener?.didUnfavorite(event)
  }
}

private extension ScheduleViewController {
  func prefersLargeTitleForDetailViewController(withTitle title: String) -> Bool {
    let font = UIFont.fos_preferredFont(forTextStyle: .largeTitle)
    let attributes = [NSAttributedString.Key.font: font]
    let attributedString = NSAttributedString(string: title, attributes: attributes)
    let preferredWidth = attributedString.size().width
    let availableWidth = view.bounds.size.width - view.layoutMargins.left - view.layoutMargins.right - 32
    return preferredWidth < availableWidth
  }
}

private extension ScheduleViewController {
  func makeTracksViewController() -> TracksViewController {
    let filtersTitle = L10n.Search.Filter.title
    let filtersAction = #selector(didTapChangeFilter)
    let filtersButton = UIBarButtonItem(title: filtersTitle, style: .plain, target: self, action: filtersAction)
    filtersButton.accessibilityIdentifier = "filters"
    self.filtersButton = filtersButton

    let tracksViewController = TracksViewController(style: .fos_insetGrouped)
    tracksViewController.title = L10n.Search.title
    tracksViewController.navigationItem.rightBarButtonItem = filtersButton
    tracksViewController.navigationItem.largeTitleDisplayMode = .always
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

  func makeEventsViewController(for track: Track) -> EventsViewController {
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

    return eventsViewController
  }

  func makeWelcomeViewController() -> WelcomeViewController {
    WelcomeViewController(year: year ?? 2022) // FIXME: remove default value
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
