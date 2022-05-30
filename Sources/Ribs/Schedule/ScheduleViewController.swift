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
  func select(_ track: Track)
  func selectTracksSection(_ section: String)
  func deselectSearchResult()

  func canFavorite(_ track: Track) -> Bool
  func toggleFavorite(_ track: Track?)
}

final class ScheduleViewController: UISplitViewController {
  weak var listener: SchedulePresentableListener?

  var year: Year? {
    didSet { welcomeViewController?.year = year }
  }

  var tracksSectionIndexTitles: [String] = []

  private weak var eventsViewController: EventsViewController?
  private weak var resultViewController: UIViewController?
  private weak var tracksViewController: TracksViewController?
  private weak var welcomeViewController: WelcomeViewController?
  private weak var filtersButton: UIBarButtonItem?

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

  func showWelcome() {
    let welcomeViewController = makeWelcomeViewController()
    showDetailViewController(welcomeViewController)
  }

  func showDetail(_ viewControllable: ViewControllable) {
    showDetailViewController(viewControllable.uiviewController)
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

extension ScheduleViewController: UISplitViewControllerDelegate {
  func splitViewController(_: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto _: UIViewController) -> Bool {
    secondaryViewController is WelcomeViewController
  }

  func splitViewController(_: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
    guard let navigationController = primaryViewController as? UINavigationController else { return nil }
    return navigationController.topViewController is TracksViewController ? makeWelcomeViewController() : nil
  }
}

private extension ScheduleViewController {
  @objc func didTapChangeFilter() {
    listener?.selectFilters()
  }

  func showDetailViewController(_ detailViewController: UIViewController) {
    if detailViewController != resultViewController {
      listener?.deselectSearchResult()
    }

    if let title = detailViewController.title, prefersLargeTitleForDetailViewController(withTitle: title) {
      detailViewController.navigationItem.largeTitleDisplayMode = .always
    } else {
      detailViewController.navigationItem.largeTitleDisplayMode = .never
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

  private func prefersLargeTitleForDetailViewController(withTitle title: String) -> Bool {
    let font = UIFont.fos_preferredFont(forTextStyle: .largeTitle)
    let attributes = [NSAttributedString.Key.font: font]
    let attributedString = NSAttributedString(string: title, attributes: attributes)
    let preferredWidth = attributedString.size().width
    let availableWidth = view.bounds.size.width - view.layoutMargins.left - view.layoutMargins.right - 32
    return preferredWidth < availableWidth
  }
}
