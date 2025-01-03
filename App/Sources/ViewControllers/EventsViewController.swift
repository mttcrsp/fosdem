import UIKit

/// @mockable
protocol EventsViewControllerDataSource: AnyObject {
  func events(in eventsViewController: EventsViewController) -> [Event]
  func eventsViewController(_ eventsViewController: EventsViewController, captionFor event: Event) -> String?
}

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
  weak var delegate: EventsViewControllerDelegate?
  weak var dataSource: EventsViewControllerDataSource? {
    didSet { reloadData() }
  }

  weak var favoritesDataSource: EventsViewControllerFavoritesDataSource?
  weak var favoritesDelegate: EventsViewControllerFavoritesDelegate?

  weak var liveDataSource: EventsViewControllerLiveDataSource?
  weak var deleteDelegate: EventsViewControllerDeleteDelegate?

  var emptyBackgroundTitle: String? {
    get { emptyBackgroundView.title }
    set { emptyBackgroundView.title = newValue }
  }

  var emptyBackgroundMessage: String? {
    get { emptyBackgroundView.message }
    set { emptyBackgroundView.message = newValue }
  }

  private lazy var emptyBackgroundView = TableBackgroundView()
  private var diffableDataSource: EventsViewControllerDiffableDataSource?

  func reloadData(animatingDifferences animated: Bool = false) {
    guard let diffableDataSource, let dataSource else { return }

    var snapshot = NSDiffableDataSourceSnapshot<Event, Event>()
    for event in dataSource.events(in: self) {
      snapshot.appendSections([event])
      snapshot.appendItems([event], toSection: event)
    }

    diffableDataSource.apply(snapshot, animatingDifferences: animated) { [weak self] in
      guard let self else { return }
      tableView.backgroundView = snapshot.numberOfSections == 0 ? emptyBackgroundView : nil
    }
  }

  func reloadLiveStatus() {
    guard viewIfLoaded?.window != nil else { return }

    for indexPath in tableView.indexPathsForVisibleRows ?? [] {
      if let cell = tableView.cellForRow(at: indexPath) {
        if let event = diffableDataSource?.itemIdentifier(for: indexPath) {
          cell.showsLiveIndicator = shouldShowLiveIndicator(for: event)
        }
      }
    }
  }

  func select(_ event: Event) {
    if let indexPath = diffableDataSource?.indexPath(for: event) {
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
    diffableDataSource?.deleteDelegate = self

    reloadData()
  }

  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard let event = diffableDataSource?.itemIdentifier(for: .init(row: 0, section: section)) else { return nil }
    let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: LabelTableHeaderFooterView.reuseIdentifier) as! LabelTableHeaderFooterView
    view.text = dataSource?.eventsViewController(self, captionFor: event)
    return view
  }

  override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let event = diffableDataSource?.itemIdentifier(for: indexPath) else { return }
    delegate?.eventsViewController(self, didSelect: event)
  }
  
  override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
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

extension EventsViewController: EventsViewControllerDiffableDataSourceDeleteDelegate {
  fileprivate func eventsDataSource(_ eventsDataSource: EventsViewControllerDiffableDataSource, didDelete event: Event) {
    deleteDelegate?.eventsViewController(self, didDelete: event)
  }
}

private protocol EventsViewControllerDiffableDataSourceDeleteDelegate: AnyObject {
  func eventsDataSource(_ eventsDataSource: EventsViewControllerDiffableDataSource, didDelete event: Event)
}

private final class EventsViewControllerDiffableDataSource: UITableViewDiffableDataSource<Event, Event> {
  weak var deleteDelegate: EventsViewControllerDiffableDataSourceDeleteDelegate?
  
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if let event = itemIdentifier(for: indexPath) {
      deleteDelegate?.eventsDataSource(self, didDelete: event)
    }
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
    get {
      imageView?.image == .liveIndicator
    }
    set {
      imageView?.image = newValue ? .liveIndicator : nil
      imageView?.accessibilityIdentifier = newValue ? "live" : nil
    }
  }
}

private extension UIImage {
  static let liveIndicator: UIImage = {
    let size = CGSize(width: 12, height: 12)
    let rect = CGRect(origin: .zero, size: size)
    let render = UIGraphicsImageRenderer(bounds: rect)
    return render.image { context in
      context.cgContext.setFillColor(UIColor.systemRed.cgColor)
      UIBezierPath(ovalIn: rect).fill()
    }
  }()
}
