import UIKit

/// @mockable
protocol EventsViewControllerLiveDataSource: AnyObject {
  func eventsViewController(_ eventsViewController: EventsViewController, shouldShowLiveIndicatorFor event: Event) -> Bool
}

/// @mockable
protocol EventsViewControllerFavoritesDataSource: AnyObject {
  func eventsViewController(_ eventsViewController: EventsViewController, canFavorite event: Event) -> Bool
}

/// @mockable
protocol EventsViewControllerDelegate: AnyObject {
  func eventsViewController(_ eventsViewController: EventsViewController, didSelect event: Event)
  func eventsViewController(_ eventsViewController: EventsViewController, captionFor event: Event) -> String?
}

/// @mockable
protocol EventsViewControllerFavoritesDelegate: AnyObject {
  func eventsViewController(_ eventsViewController: EventsViewController, didFavorite event: Event)
  func eventsViewController(_ eventsViewController: EventsViewController, didUnfavorite event: Event)
}

/// @mockable
protocol EventsViewControllerDeleteDelegate: AnyObject {
  func eventsViewController(_ eventsViewController: EventsViewController, didDelete event: Event)
}

class EventsViewController: UITableViewController {
  var emptyBackgroundTitle: String?
  var emptyBackgroundMessage: String?
  weak var delegate: EventsViewControllerDelegate?
  weak var deleteDelegate: EventsViewControllerDeleteDelegate?
  weak var favoritesDataSource: EventsViewControllerFavoritesDataSource?
  weak var favoritesDelegate: EventsViewControllerFavoritesDelegate?
  weak var liveDataSource: EventsViewControllerLiveDataSource?
  private var diffableDataSource: DiffableDataSource?
  private(set) var events: [Event] = []
  private lazy var emptyBackgroundView = TableBackgroundView()
  
  func reloadData(animatingDifferences animated: Bool = false) {
    guard let diffableDataSource else { return }

    var snapshot = NSDiffableDataSourceSnapshot<Event, Event>()
    for event in events {
      snapshot.appendSections([event])
      snapshot.appendItems([event], toSection: event)
    }

    diffableDataSource.apply(snapshot, animatingDifferences: animated) { [weak self] in
      guard let self else { return }
      
      let isEmpty = snapshot.numberOfSections == 0
      if #available(iOS 17.0, *) {
        var configuration = UIContentUnavailableConfiguration.empty()
        configuration.text = emptyBackgroundTitle
        configuration.secondaryText = emptyBackgroundMessage
        contentUnavailableConfiguration = isEmpty ? configuration : nil
      } else {
        emptyBackgroundView.title = emptyBackgroundTitle
        emptyBackgroundView.message = emptyBackgroundMessage
        tableView.backgroundView = isEmpty ? emptyBackgroundView : nil
      }
    }
  }

  func reloadLiveStatus() {
    guard viewIfLoaded?.window != nil, let diffableDataSource else { return }

    var events: [Event] = []
    for indexPath in tableView.indexPathsForVisibleRows ?? [] {
      if let cell = tableView.cellForRow(at: indexPath) {
        if let event = diffableDataSource.itemIdentifier(for: indexPath) {
          let oldStatus = cell.showsLiveIndicator
          let newStatus = shouldShowLiveIndicator(for: event)
          if oldStatus != newStatus {
            events.append(event)
          }
        }
      }
    }

    var snapshot = diffableDataSource.snapshot()
    snapshot.reloadItems(events)
    diffableDataSource.apply(snapshot, animatingDifferences: false)
  }

  func setEvents(_ events: [Event], animatingDifferences animated: Bool = false) {
    self.events = events
    reloadData(animatingDifferences: animated)
  }

  func selectEvent(_ event: Event) {
    if let section = events.firstIndex(of: event) {
      let indexPath = IndexPath(row: 0, section: section)
      tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.estimatedRowHeight = 44
    tableView.estimatedSectionHeaderHeight = 44
    tableView.accessibilityIdentifier = "events"
    tableView.rowHeight = UITableView.automaticDimension
    tableView.sectionHeaderHeight = UITableView.automaticDimension
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
    tableView.register(LabelTableHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: LabelTableHeaderFooterView.reuseIdentifier)

    diffableDataSource = .init(tableView: tableView) { [weak self] tableView, indexPath, event in
      let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
      cell.showsLiveIndicator = self?.shouldShowLiveIndicator(for: event) ?? false
      cell.configure(with: event)
      return cell
    }
    diffableDataSource?.defaultRowAnimation = .fade
    diffableDataSource?.commitEditingStyle = { [weak self] _, _, indexPath in
      if let self, let event = diffableDataSource?.itemIdentifier(for: indexPath) {
        deleteDelegate?.eventsViewController(self, didDelete: event)
      }
    }

    reloadData(animatingDifferences: false)
  }

  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard let event = diffableDataSource?.itemIdentifier(for: .init(row: 0, section: section)) else { return nil }
    let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: LabelTableHeaderFooterView.reuseIdentifier) as! LabelTableHeaderFooterView
    view.text = delegate?.eventsViewController(self, captionFor: event)
    return view
  }

  override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let event = diffableDataSource?.itemIdentifier(for: indexPath) else { return }
    delegate?.eventsViewController(self, didSelect: event)
  }

  override func tableView(_: UITableView, editingStyleForRowAt _: IndexPath) -> UITableViewCell.EditingStyle {
    deleteDelegate == nil ? .none : .delete
  }

  override func tableView(_: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    UISwipeActionsConfiguration(actions: actions(at: indexPath))
  }

  @available(iOS 13.0, *)
  override func tableView(_: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
    UIContextMenuConfiguration(actions: actions(at: indexPath))
  }

  private func actions(at indexPath: IndexPath) -> [Action] {
    guard let favoritesDataSource, let event = diffableDataSource?.itemIdentifier(for: indexPath) else {
      return []
    }

    if favoritesDataSource.eventsViewController(self, canFavorite: event) {
      let title = L10n.Event.add
      let image = UIImage(systemName: "calendar.badge.plus")
      return [Action(title: title, image: image) { [weak self] in
        self?.didFavorite(event)
      }]
    } else {
      let title = L10n.Event.remove
      let image = UIImage(systemName: "calendar.badge.minus")
      return [Action(title: title, image: image, style: .destructive) { [weak self] in
        self?.didUnfavorite(event)
      }]
    }
  }

  private func didFavorite(_ event: Event) {
    favoritesDelegate?.eventsViewController(self, didFavorite: event)
  }

  private func didUnfavorite(_ event: Event) {
    favoritesDelegate?.eventsViewController(self, didUnfavorite: event)
  }

  private func shouldShowLiveIndicator(for event: Event) -> Bool {
    liveDataSource?.eventsViewController(self, shouldShowLiveIndicatorFor: event) ?? false
  }
}

private final class DiffableDataSource: UITableViewDiffableDataSource<Event, Event> {
  var commitEditingStyle: ((UITableView, UITableViewCell.EditingStyle, IndexPath) -> Void)?
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    commitEditingStyle?(tableView, editingStyle, indexPath)
  }
}

private extension UITableViewCell {
  func configure(with event: Event) {
    textLabel?.text = event.title
    textLabel?.numberOfLines = 0
    textLabel?.font = .fos_preferredFont(forTextStyle: .body)
    accessoryType = .disclosureIndicator
    accessibilityIdentifier = event.title
  }

  var showsLiveIndicator: Bool {
    get { imageView?.image == .live }
    set {
      imageView?.image = newValue ? .live : nil
      imageView?.tintColor = .systemRed
      imageView?.accessibilityIdentifier = newValue ? "live" : nil
      if #available(iOS 17.0, *) {
        imageView?.addSymbolEffect(.pulse)
      }
    }
  }
}

private extension UIImage {
  static let live = UIImage(systemName: "circle.fill")?
    .withConfiguration(UIImage.SymbolConfiguration(pointSize: 12))
}
