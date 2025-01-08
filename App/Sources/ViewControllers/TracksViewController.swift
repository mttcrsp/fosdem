import UIKit

struct TracksSection {
  var title: String?
  var accessibilityIdentifier: String?
  var tracks: [Track]
}

/// @mockable
protocol TracksViewControllerIndexDataSource: AnyObject {
  func sectionIndexTitles(in tracksViewController: TracksViewController) -> [String]
}

/// @mockable
protocol TracksViewControllerFavoritesDataSource: AnyObject {
  func tracksViewController(_ tracksViewController: TracksViewController, canFavorite track: Track) -> Bool
}

/// @mockable
protocol TracksViewControllerDelegate: AnyObject {
  func tracksViewController(_ tracksViewController: TracksViewController, didSelect track: Track)
}

/// @mockable
protocol TracksViewControllerIndexDelegate: AnyObject {
  func tracksViewController(_ tracksViewController: TracksViewController, didSelect section: Int)
}

/// @mockable
protocol TracksViewControllerFavoritesDelegate: AnyObject {
  func tracksViewController(_ tracksViewController: TracksViewController, didFavorite track: Track)
  func tracksViewController(_ tracksViewController: TracksViewController, didUnfavorite track: Track)
}

class TracksViewController: UITableViewController {
  fileprivate struct Section: Hashable {
    var title: String?
    var accessibilityIdentifier: String?
  }

  fileprivate struct Item: Hashable {
    var track: Track
    /// Diffable data sources expect items to only appear once in a
    /// table/collection view. This is a precondition for diffing to work. This
    /// means that the Track type is not enough to serve as an item. Each track
    /// needs to be enriched with something specific to the section it appears
    /// in to get unique items.
    var sectionAccessibilityIdentifier: String?
  }

  weak var delegate: TracksViewControllerDelegate?
  weak var indexDataSource: TracksViewControllerIndexDataSource?
  weak var indexDelegate: TracksViewControllerIndexDelegate?
  weak var favoritesDataSource: TracksViewControllerFavoritesDataSource?
  weak var favoritesDelegate: TracksViewControllerFavoritesDelegate?
  private lazy var feedbackGenerator = UISelectionFeedbackGenerator()
  private lazy var diffableDataSource: TracksDiffableDataSource = {
    let diffableDataSource = TracksDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
      let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
      cell.configure(with: item.track)
      return cell
    }
    diffableDataSource.sectionIndexTitles = { [weak self] _ in
      guard let self else { return nil }
      return indexDataSource?.sectionIndexTitles(in: self)
    }
    diffableDataSource.sectionForSectionIndexTitle = { [weak self] _, _, index in
      guard let self else { return 0 }

      // HACK: UITableView only supports using section index titles pointing
      // to the first element of a given section. However here I want the
      // indices to point to arbitrary index paths. In order to achieve this
      // here I am always returning the first section as the target section
      // for handling by UITableView and preventing content offset updates by
      // replacing -[UIScrollView setContentOffset:] with an empty
      // implementation. Clients of TracksViewController delegate API will
      // then be able to apply their custom logic to select a given index
      // path. The only thing that this implementation is missing when
      // compared with the original table view one is handling of prevention
      // of unnecessary haptic feedback responses when no movement should be
      // performed.
      let originalMethod = class_getInstanceMethod(UIScrollView.self, #selector(setter: UIScrollView.contentOffset))
      let swizzledMethod = class_getInstanceMethod(UIScrollView.self, #selector(setter: UIScrollView.fos_contentOffset))
      if let method1 = originalMethod, let method2 = swizzledMethod {
        method_exchangeImplementations(method1, method2)
        OperationQueue.main.addOperation { [weak self] in
          method_exchangeImplementations(method1, method2)

          if let self {
            feedbackGenerator.selectionChanged()
            indexDelegate?.tracksViewController(self, didSelect: index)
          }
        }
      }

      return 0
    }

    return diffableDataSource
  }()

  func setSections(_ models: [TracksSection], animatingDifferences: Bool = false) {
    var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
    for model in models {
      let section = Section(title: model.title, accessibilityIdentifier: model.accessibilityIdentifier)
      let items = model.tracks.map { track in
        Item(track: track, sectionAccessibilityIdentifier: model.accessibilityIdentifier)
      }

      snapshot.appendSections([section])
      snapshot.appendItems(items, toSection: section)
    }

    diffableDataSource.apply(snapshot, animatingDifferences: animatingDifferences)
  }

  func scrollToRow(at indexPath: IndexPath, at scrollPosition: UITableView.ScrollPosition, animated: Bool) {
    tableView.scrollToRow(at: indexPath, at: scrollPosition, animated: animated)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.tableFooterView = UIView()
    tableView.estimatedRowHeight = 44
    tableView.estimatedSectionHeaderHeight = 44
    tableView.accessibilityIdentifier = "tracks"
    tableView.rowHeight = UITableView.automaticDimension
    tableView.sectionHeaderHeight = UITableView.automaticDimension
    tableView.showsVerticalScrollIndicator = indexDataSource == nil
    tableView.sectionHeaderHeight = indexDataSource == nil ? 0 : UITableView.automaticDimension
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
    tableView.register(LabelTableHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: LabelTableHeaderFooterView.reuseIdentifier)
  }

  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard let section = diffableDataSource.sectionIdentifier(for: section) else { return nil }
    let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: LabelTableHeaderFooterView.reuseIdentifier) as! LabelTableHeaderFooterView
    view.accessibilityIdentifier = section.accessibilityIdentifier
    view.text = section.title
    view.textColor = .label
    view.font = .fos_preferredFont(forTextStyle: .headline)
    return view
  }

  override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let track = track(at: indexPath) {
      delegate?.tracksViewController(self, didSelect: track)
    }
  }

  override func tableView(_: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    UISwipeActionsConfiguration(actions: actions(at: indexPath))
  }

  @available(iOS 13.0, *)
  override func tableView(_: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
    UIContextMenuConfiguration(actions: actions(at: indexPath))
  }

  private func actions(at indexPath: IndexPath) -> [Action] {
    guard let favoritesDataSource, let track = track(at: indexPath) else {
      return []
    }

    if favoritesDataSource.tracksViewController(self, canFavorite: track) {
      let title = L10n.favorite
      let image = UIImage(systemName: "star.fill")
      return [Action(title: title, image: image) { [weak self] in
        self?.didFavorite(track)
      }]
    } else {
      let title = L10n.unfavorite
      let image = UIImage(systemName: "star.slash.fill")
      return [Action(title: title, image: image, style: .destructive) { [weak self] in
        self?.didUnfavorite(track)
      }]
    }
  }

  private func didFavorite(_ track: Track) {
    favoritesDelegate?.tracksViewController(self, didFavorite: track)
  }

  private func didUnfavorite(_ track: Track) {
    favoritesDelegate?.tracksViewController(self, didUnfavorite: track)
  }

  private func track(at indexPath: IndexPath) -> Track? {
    diffableDataSource.itemIdentifier(for: indexPath)?.track
  }
}

private final class TracksDiffableDataSource: UITableViewDiffableDataSource<TracksViewController.Section, TracksViewController.Item> {
  var sectionIndexTitles: ((UITableView) -> [String]?)?
  override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
    sectionIndexTitles?(tableView)
  }

  var sectionForSectionIndexTitle: ((UITableView, String, Int) -> Int)?
  override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
    sectionForSectionIndexTitle?(tableView, title, index) ?? 0
  }
}

private extension UITableViewCell {
  func configure(with track: Track) {
    textLabel?.numberOfLines = 0
    textLabel?.text = track.formattedName
    textLabel?.font = .fos_preferredFont(forTextStyle: .body)
    accessoryType = .disclosureIndicator
    accessibilityIdentifier = track.formattedName
  }
}

@objc private extension UIScrollView {
  var fos_contentOffset: CGPoint {
    get { .zero }
    set {}
  }
}
