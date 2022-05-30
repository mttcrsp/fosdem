import RIBs
import UIKit

struct TracksSection {
  let title: String?
  let accessibilityIdentifier: String?
  let tracks: [Track]
}

protocol SchedulePresentableListener: AnyObject {
  var tracksSections: [TracksSection] { get }

  func selectFilters()
  func select(_ filter: TracksFilter)
  func select(_ event: Event)
  func select(_ track: Track)
  func selectTracksSection(_ section: String)
  func deselectEvent()
  func deselectSearchResult()

  func canFavorite(_ event: Event) -> Bool
  func canFavorite(_ track: Track) -> Bool
  func toggleFavorite(_ event: Event)
  func toggleFavorite(_ track: Track?)
}

final class ScheduleViewController: UISplitViewController {
  weak var listener: SchedulePresentableListener?

  var showsFavoriteTrack = false {
    didSet {
      favoriteButton.title = showsFavoriteTrack ? L10n.unfavorite : L10n.favorite
      favoriteButton.accessibilityIdentifier = showsFavoriteTrack ? "unfavorite" : "favorite"
    }
  }

  var year: Year? {
    didSet { welcomeViewController?.year = year }
  }

  var tracksSectionIndexTitles: [String] = []

  private var events: [Event] = []
  private var eventsCaptions: [Event: String] = [:]

  private weak var eventViewController: UIViewController?
  private weak var eventsViewController: EventsViewController?
  private weak var resultViewController: UIViewController?
  private weak var tracksViewController: TracksViewController?
  private weak var welcomeViewController: WelcomeViewController?
  private weak var filtersButton: UIBarButtonItem?

  private lazy var favoriteButton: UIBarButtonItem = {
    let favoriteAction = #selector(didToggleFavorite)
    let favoriteButton = UIBarButtonItem(title: nil, style: .plain, target: self, action: favoriteAction)
    return favoriteButton
  }()

  init() {
    super.init(nibName: nil, bundle: nil)

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

    viewControllers = [tracksNavigationController]
    if traitCollection.horizontalSizeClass == .regular {
      viewControllers.append(makeWelcomeViewController())
    }
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    delegate = self
    maximumPrimaryColumnWidth = 375
    preferredPrimaryColumnWidthFraction = 0.4
  }
}

extension ScheduleViewController: ScheduleViewControllable {
  func showEvent(_ eventViewControllable: ViewControllable) {
    let eventViewController = eventViewControllable.uiviewController
    self.eventViewController = eventViewController
    eventsViewController?.show(eventViewController, sender: nil)
  }

  func addSearch(_ searchViewControllable: ViewControllable) {
    if let searchController = searchViewControllable.uiviewController as? UISearchController {
      tracksViewController?.addSearchViewController(searchController)
    }
  }

  func showSearchResult(_ resultViewControllable: ViewControllable) {
    let resultViewController = resultViewControllable.uiviewController
    self.resultViewController = resultViewController
    showDetailViewController(resultViewController)
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
    showDetailViewController(eventsNavigationController)
  }

  func showFilters(_ filters: [TracksFilter], selectedFilter: TracksFilter) {
    let filtersViewController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    filtersViewController.popoverPresentationController?.barButtonItem = filtersButton
    filtersViewController.view.accessibilityIdentifier = "filters"

    for filter in filters where filter != selectedFilter {
      let actionHandler: (UIAlertAction) -> Void = { [weak self] _ in self?.listener?.select(filter) }
      let action = UIAlertAction(title: filter.title, style: .default, handler: actionHandler)
      filtersViewController.addAction(action)
    }

    let cancelTitle = L10n.Search.Filter.cancel
    let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel)
    filtersViewController.addAction(cancelAction)

    tracksViewController?.present(filtersViewController, animated: true)
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
    listener?.select(track)
  }
}

extension ScheduleViewController: TracksViewControllerFavoritesDataSource {
  func tracksViewController(_: TracksViewController, canFavorite track: Track) -> Bool {
    listener?.canFavorite(track) ?? false
  }
}

extension ScheduleViewController: TracksViewControllerFavoritesDelegate {
  func tracksViewController(_: TracksViewController, didToggleFavorite track: Track) {
    listener?.toggleFavorite(track)
  }
}

extension ScheduleViewController: TracksViewControllerIndexDataSource {
  func sectionIndexTitles(in _: TracksViewController) -> [String] {
    tracksSectionIndexTitles
  }
}

extension ScheduleViewController: TracksViewControllerIndexDelegate {
  func tracksViewController(_: TracksViewController, didSelect section: Int) {
    listener?.selectTracksSection(tracksSectionIndexTitles[section])
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
    listener?.select(event)
  }
}

extension ScheduleViewController: EventsViewControllerFavoritesDataSource {
  func eventsViewController(_: EventsViewController, canFavorite event: Event) -> Bool {
    listener?.canFavorite(event) ?? false
  }
}

extension ScheduleViewController: EventsViewControllerFavoritesDelegate {
  func eventsViewController(_: EventsViewController, didToggleFavorite event: Event) {
    listener?.toggleFavorite(event)
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

extension ScheduleViewController: UINavigationControllerDelegate {
  func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated _: Bool) {
    if !navigationController.viewControllers.contains(where: { viewController in viewController === eventViewController }) {
      listener?.deselectEvent()
    }
  }
}

private extension ScheduleViewController {
  @objc func didToggleFavorite() {
    listener?.toggleFavorite(nil)
  }

  @objc func didTapChangeFilter() {
    listener?.selectFilters()
  }

  func prefersLargeTitleForDetailViewController(withTitle title: String) -> Bool {
    let font = UIFont.fos_preferredFont(forTextStyle: .largeTitle)
    let attributes = [NSAttributedString.Key.font: font]
    let attributedString = NSAttributedString(string: title, attributes: attributes)
    let preferredWidth = attributedString.size().width
    let availableWidth = view.bounds.size.width - view.layoutMargins.left - view.layoutMargins.right - 32
    return preferredWidth < availableWidth
  }

  func showDetailViewController(_ detailViewController: UIViewController) {
    if detailViewController != resultViewController {
      listener?.deselectSearchResult()
    }

    tracksViewController?.showDetailViewController(detailViewController, sender: nil)
    UIAccessibility.post(notification: .screenChanged, argument: detailViewController.view)
  }

  func makeWelcomeViewController() -> WelcomeViewController {
    let welcomeViewController = WelcomeViewController()
    welcomeViewController.year = year
    self.welcomeViewController = welcomeViewController
    return welcomeViewController
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
