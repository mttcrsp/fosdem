import UIKit

/// @mockable
protocol TracksViewControllerDataSource: AnyObject {
  func numberOfSections(in tracksViewController: TracksViewController) -> Int
  func tracksViewController(_ tracksViewController: TracksViewController, numberOfTracksIn section: Int) -> Int
  func tracksViewController(_ tracksViewController: TracksViewController, trackAt indexPath: IndexPath) -> Track
}

/// @mockable
protocol TracksViewControllerIndexDataSource: AnyObject {
  func sectionIndexTitles(in tracksViewController: TracksViewController) -> [String]
  func tracksViewController(_ tracksViewController: TracksViewController, titleForSectionAt section: Int) -> String?
  func tracksViewController(_ tracksViewController: TracksViewController, accessibilityIdentifierForSectionAt section: Int) -> String?
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
  weak var dataSource: TracksViewControllerDataSource?
  weak var delegate: TracksViewControllerDelegate?

  weak var indexDataSource: TracksViewControllerIndexDataSource?
  weak var indexDelegate: TracksViewControllerIndexDelegate?

  weak var favoritesDataSource: TracksViewControllerFavoritesDataSource?
  weak var favoritesDelegate: TracksViewControllerFavoritesDelegate?

  private lazy var feedbackGenerator = UISelectionFeedbackGenerator()

  func reloadData() {
    if isViewLoaded {
      tableView.reloadData()
    }
  }

  func performBatchUpdates(_ updates: () -> Void) {
    tableView.performBatchUpdates(updates) { [weak self] _ in
      // WORKAROUND: This call to -[UITableView reloadData] workarounds an issue
      // that takes place when a section is deleted by swiping to delete on a
      // row from a different section. On iOS 11 and 12, this issue results in
      // some cells not being visible until the next layout pass. On iOS 13,
      // this issue causes the table view to stop responding to touches.
      self?.tableView.reloadData()
    }
  }

  func insertFavoritesSection() {
    let section = IndexSet([0])
    tableView.insertSections(section, with: .automatic)
  }

  func deleteFavoritesSection() {
    let section = IndexSet([0])
    tableView.deleteSections(section, with: .automatic)
  }

  func insertFavorite(at index: Int) {
    let indexPath = IndexPath(row: index, section: 0)
    tableView.insertRows(at: [indexPath], with: .automatic)
  }

  func deleteFavorite(at index: Int) {
    let indexPath = IndexPath(row: index, section: 0)
    tableView.deleteRows(at: [indexPath], with: .automatic)
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

  override func numberOfSections(in _: UITableView) -> Int {
    dataSource?.numberOfSections(in: self) ?? 0
  }

  override func sectionIndexTitles(for _: UITableView) -> [String]? {
    indexDataSource?.sectionIndexTitles(in: self)
  }

  override func tableView(_: UITableView, sectionForSectionIndexTitle _: String, at index: Int) -> Int {
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

        if let self = self {
          self.feedbackGenerator.selectionChanged()
          self.indexDelegate?.tracksViewController(self, didSelect: index)
        }
      }
    }

    return 0
  }

  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: LabelTableHeaderFooterView.reuseIdentifier) as! LabelTableHeaderFooterView
    view.accessibilityIdentifier = indexDataSource?.tracksViewController(self, accessibilityIdentifierForSectionAt: section)
    view.text = indexDataSource?.tracksViewController(self, titleForSectionAt: section)
    view.font = .fos_preferredFont(forTextStyle: .headline)
    view.textColor = .label
    return view
  }

  override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
    dataSource?.tracksViewController(self, numberOfTracksIn: section) ?? 0
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
    if let track = dataSource?.tracksViewController(self, trackAt: indexPath) {
      cell.configure(with: track)
    }
    return cell
  }

  override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let track = dataSource?.tracksViewController(self, trackAt: indexPath) {
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
    guard let dataSource = dataSource, let favoritesDataSource = favoritesDataSource else {
      return []
    }

    let track = dataSource.tracksViewController(self, trackAt: indexPath)

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
}

private extension UITableViewCell {
  func configure(with track: Track) {
    textLabel?.numberOfLines = 0
    textLabel?.text = track.name
    textLabel?.font = .fos_preferredFont(forTextStyle: .body)
    accessoryType = .disclosureIndicator
    accessibilityIdentifier = track.name
  }
}

@objc private extension UIScrollView {
  var fos_contentOffset: CGPoint {
    get { .zero }
    set {}
  }
}
