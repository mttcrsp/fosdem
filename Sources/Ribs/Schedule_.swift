import RIBs
import UIKit

struct TracksSection {
  let title: String?
  let accessibilityIdentifier: String?
  let tracks: [Track]
}

typealias ScheduleDependency = HasEventBuilder
  & HasFavoritesService
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
    let router = ScheduleRouter(interactor: interactor, viewController: viewController, eventBuilder: dependency.eventBuilder)
    viewController.listener = interactor
    return router
  }
}

protocol ScheduleRouting: ViewableRouting {
  func routeToEvent(_ event: Event?)
}

final class ScheduleRouter: ViewableRouter<ScheduleInteractable, ScheduleViewControllable> {
  private var eventRouter: ViewableRouting?

  private let eventBuilder: EventBuildable

  init(interactor: ScheduleInteractable, viewController: ScheduleViewControllable, eventBuilder: EventBuildable) {
    self.eventBuilder = eventBuilder
    super.init(interactor: interactor, viewController: viewController)
    interactor.router = self
  }
}

extension ScheduleRouter: ScheduleRouting {
  func routeToEvent(_ event: Event?) {
    if let eventRouter = eventRouter {
      detachChild(eventRouter)
      self.eventRouter = nil
    }

    if let event = event {
      let eventRouter = eventBuilder.build(with: event)
      self.eventRouter = eventRouter
      attachChild(eventRouter)
      viewController.showEvent(eventRouter.viewControllable)
    }
  }
}

protocol ScheduleInteractable: Interactable {
  var router: ScheduleRouting? { get set }
}

final class ScheduleInteractor: PresentableInteractor<SchedulePresentable>, ScheduleInteractable {
  weak var router: ScheduleRouting?

  private var observer: NSObjectProtocol?
  private var selectedFilter: TracksFilter = .all
  private var selectedTrack: Track?

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
      if let self = self, let track = self.selectedTrack {
        self.presenter.showsFavoriteTrack = self.dependency.favoritesService.contains(track)
      }
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

  func didToggleFavorite() {
    guard let selectedTrack = selectedTrack else { return }

    if dependency.favoritesService.contains(selectedTrack) {
      dependency.favoritesService.removeTrack(withIdentifier: selectedTrack.name)
    } else {
      dependency.favoritesService.addTrack(withIdentifier: selectedTrack.name)
    }
  }

  func didSelectFilters() {
    presenter.showFilters(dependency.tracksService.filters, selectedFilter: selectedFilter)
  }

  func didSelect(_ event: Event) {
    router?.routeToEvent(event)
  }

  func didSelect(_ selectedFilter: TracksFilter) {
    self.selectedFilter = selectedFilter
    presenter.reloadData()
  }

  func didSelect(_ selectedTrack: Track) {
    self.selectedTrack = selectedTrack

    let operation = EventsForTrack(track: selectedTrack.name)
    dependency.persistenceService.performRead(operation) { [weak self] result in
      DispatchQueue.main.async {
        guard let self = self else { return }

        switch result {
        case .failure:
          self.presenter.showError()
        case let .success(events):
          self.presenter.showTrack(selectedTrack, events: events)
          self.presenter.showsFavoriteTrack = self.dependency.favoritesService.contains(selectedTrack)
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

  func didDeselectEvent() {
    router?.routeToEvent(nil)
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

  var tracksSections: [TracksSection] {
    var sections: [TracksSection] = []

    if hasFavoriteTracks {
      let sectionTitle = L10n.Search.Filter.favorites
      let sectionAccessibilityIdentifier = "favorites"
      let sectionTracks = filteredFavoriteTracks
      sections.append(TracksSection(title: sectionTitle, accessibilityIdentifier: sectionAccessibilityIdentifier, tracks: sectionTracks))
    }

    let sectionTitle = selectedFilter.title
    let sectionAccessibilityIdentifier = selectedFilter.accessibilityIdentifier
    let sectionTracks = filteredTracks
    sections.append(TracksSection(title: sectionTitle, accessibilityIdentifier: sectionAccessibilityIdentifier, tracks: sectionTracks))

    return sections
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

protocol ScheduleViewControllable: ViewControllable {
  func showEvent(_ eventViewController: ViewControllable)
}

protocol SchedulePresentable: Presentable {
  var year: Year? { get set }
  var showsFavoriteTrack: Bool { get set }
  var tracksSectionIndexTitles: [String] { get set }

  func reloadData()
  func performBatchUpdates(_ updates: () -> Void)
  func insertFavoritesSection()
  func deleteFavoritesSection()
  func insertFavorite(at index: Int)
  func deleteFavorite(at index: Int)
  func scrollToRow(at indexPath: IndexPath)

  func showError()
  func showTrack(_ track: Track, events: [Event])
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
  func didDeselectEvent()

  func didToggleFavorite()

  var tracksSections: [TracksSection] { get }
}

final class ScheduleViewController: UISplitViewController {
  weak var listener: SchedulePresentableListener?

  var showsFavoriteTrack = false {
    didSet {
      favoriteButton.title = showsFavoriteTrack ? L10n.unfavorite : L10n.favorite
      favoriteButton.accessibilityIdentifier = showsFavoriteTrack ? "unfavorite" : "favorite"
    }
  }

  var tracksSectionIndexTitles: [String] = []
  var year: Year?

  private var events: [Event] = []
  private var eventsCaptions: [Event: String] = [:]

  private weak var tracksViewController: TracksViewController?
  private weak var eventsViewController: EventsViewController?
  private weak var eventViewController: UIViewController?
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

    let tracksNavigationController = makeTracksNavigationController()
    viewControllers = [tracksNavigationController]
    if traitCollection.horizontalSizeClass == .regular {
      viewControllers.append(makeWelcomeViewController())
    }
  }

  @objc private func didToggleFavorite() {
    listener?.didToggleFavorite()
  }

  @objc private func didTapChangeFilter() {
    listener?.didSelectFilters()
  }

  private func didSelectFilter(_ filter: TracksFilter) {
    listener?.didSelect(filter)
  }
}

extension ScheduleViewController: ScheduleViewControllable {
  func showEvent(_ eventViewControllable: ViewControllable) {
    let eventViewController = eventViewControllable.uiviewController
    self.eventViewController = eventViewController
    eventsViewController?.show(eventViewController, sender: nil)
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

  func showTrack(_ track: Track, events: [Event]) {
    self.events = events
    eventsCaptions = events.captions

    let eventsNavigationController = makeEventsNavigationController(for: track)
    tracksViewController?.showDetailViewController(eventsNavigationController, sender: nil)
    UIAccessibility.post(notification: .screenChanged, argument: eventsNavigationController.view)
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
  func numberOfSections(in _: TracksViewController) -> Int {
    listener?.tracksSections.count ?? 0
  }

  func tracksViewController(_: TracksViewController, numberOfTracksIn section: Int) -> Int {
    listener?.tracksSections[section].tracks.count ?? 0
  }

  func tracksViewController(_: TracksViewController, trackAt indexPath: IndexPath) -> Track {
    listener!.tracksSections[indexPath.section].tracks[indexPath.row] // FIXME: sections handling
  }

  func tracksViewController(_: TracksViewController, titleForSectionAt section: Int) -> String? {
    listener?.tracksSections[section].title
  }

  func tracksViewController(_: TracksViewController, accessibilityIdentifierForSectionAt section: Int) -> String? {
    listener?.tracksSections[section].accessibilityIdentifier
  }
}

extension ScheduleViewController: TracksViewControllerDelegate {
  func tracksViewController(_: TracksViewController, didSelect track: Track) {
    listener?.didSelect(track)
  }
}

extension ScheduleViewController: TracksViewControllerFavoritesDataSource {
  func tracksViewController(_: TracksViewController, canFavorite track: Track) -> Bool {
    listener?.canFavoritEvent(track) ?? false
  }
}

extension ScheduleViewController: TracksViewControllerFavoritesDelegate {
  func tracksViewController(_: TracksViewController, didFavorite track: Track) {
    listener?.didFavorite(track)
  }

  func tracksViewController(_: TracksViewController, didUnfavorite track: Track) {
    listener?.didUnfavorite(track)
  }
}

extension ScheduleViewController: TracksViewControllerIndexDataSource {
  func sectionIndexTitles(in _: TracksViewController) -> [String] {
    tracksSectionIndexTitles
  }
}

extension ScheduleViewController: TracksViewControllerIndexDelegate {
  func tracksViewController(_: TracksViewController, didSelect section: Int) {
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

extension ScheduleViewController: UINavigationControllerDelegate {
  func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated _: Bool) {
    if !navigationController.viewControllers.contains(where: { viewController in viewController === eventViewController }) {
      listener?.didDeselectEvent()
    }
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
  func makeTracksNavigationController() -> UINavigationController {
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

    let tracksNavigationController = UINavigationController(rootViewController: tracksViewController)
    tracksNavigationController.navigationBar.prefersLargeTitles = true
    return tracksNavigationController
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

  func makeEventsNavigationController(for track: Track) -> UINavigationController {
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

    let eventsNavigationController = UINavigationController(rootViewController: eventsViewController)
    eventsNavigationController.delegate = self
    return eventsNavigationController
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
