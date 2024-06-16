import UIKit

protocol TracksViewControllerDataSource: AnyObject {
  func numberOfTracks(in tracksViewController: TracksViewController) -> Int
  func numberOfFavoriteTracks(in tracksViewController: TracksViewController) -> Int
  func tracksViewController(_ tracksViewController: TracksViewController, trackAt index: Int) -> Track
  func tracksViewController(_ tracksViewController: TracksViewController, favoriteTrackAt index: Int) -> Track
  func selectedFilter(in tracksViewController: TracksViewController) -> TracksFilter
}

protocol TracksViewControllerDelegate: AnyObject {
  func tracksViewController(_ tracksViewController: TracksViewController, didSelect track: Track)
}

protocol TracksViewControllerFavoritesDelegate: AnyObject {
  func tracksViewController(_ tracksViewController: TracksViewController, canFavorite track: Track) -> Bool
  func tracksViewController(_ tracksViewController: TracksViewController, didFavorite track: Track)
  func tracksViewController(_ tracksViewController: TracksViewController, didUnfavorite track: Track)
}

final class TracksViewController: UITableViewController {
  private typealias SectionIndexItem = (initial: Character, index: Int)
  fileprivate enum SectionType {
    case favorites, all
  }

  fileprivate struct Section {
    var sectionType: SectionType
    var tracks: [Item]
  }

  fileprivate struct Item {
    var track: Track
  }

  weak var dataSource: TracksViewControllerDataSource?
  weak var delegate: TracksViewControllerDelegate?
  weak var favoritesDelegate: TracksViewControllerFavoritesDelegate?

  private var items: [Item] = []
  private var favoriteItems: [Item] = []
  private var sectionIndexItems: [SectionIndexItem] = []
  private lazy var feedbackGenerator = UISelectionFeedbackGenerator()

  private var sections: [Section] {
    var sections: [Section] = []

    if !favoriteItems.isEmpty {
      sections.append(Section(sectionType: .favorites, tracks: favoriteItems))
    }

    if !items.isEmpty {
      sections.append(Section(sectionType: .all, tracks: items))
    }

    return sections
  }

  func reloadData() {
    guard let dataSource else { return }

    var favoriteItems: [Item] = []
    for index in 0 ..< dataSource.numberOfFavoriteTracks(in: self) {
      let track = dataSource.tracksViewController(self, favoriteTrackAt: index)
      favoriteItems.append(Item(track: track))
    }

    var items: [Item] = []
    for index in 0 ..< dataSource.numberOfTracks(in: self) {
      let track = dataSource.tracksViewController(self, trackAt: index)
      items.append(Item(track: track))
    }

    switch (items == self.items, favoriteItems == self.favoriteItems) {
    case (true, true):
      return
    case (false, _):
      var sectionIndexItems: [SectionIndexItem] = []
      for (index, item) in items.enumerated() {
        if let initial = item.track.name.first, sectionIndexItems.last?.initial != initial {
          sectionIndexItems.append((initial, index))
        }
      }

      self.sectionIndexItems = sectionIndexItems
      self.favoriteItems = favoriteItems
      self.items = items
      tableView.reloadData()
    case (true, false):
      guard tableView.window != nil else {
        self.favoriteItems = favoriteItems
        tableView.reloadData()
        return
      }

      tableView.performBatchUpdates {
        switch (self.favoriteItems.isEmpty, favoriteItems.isEmpty) {
        case (true, true): break
        case (true, false):
          self.tableView.insertSections(.init(integer: 0), with: .automatic)
        case (false, true):
          self.tableView.deleteSections(.init(integer: 0), with: .automatic)
        case (false, false):
          for difference in favoriteItems.difference(from: self.favoriteItems) {
            switch difference {
            case let .insert(row, _, _):
              self.tableView.insertRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
            case let .remove(row, _, _):
              self.tableView.deleteRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
            }
          }
        }

        self.favoriteItems = favoriteItems
      } completion: { [weak self] _ in
        // WORKAROUND: This call to -[UITableView reloadData] workarounds an issue
        // that takes place when a section is deleted by swiping to delete on a
        // row from a different section. On iOS 11 and 12, this issue results in
        // some cells not being visible until the next layout pass. On iOS 13,
        // this issue causes the table view to stop responding to touches.
        self?.tableView.reloadData()
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.tableFooterView = UIView()
    tableView.showsVerticalScrollIndicator = false
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
    tableView.register(LabelTableHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: LabelTableHeaderFooterView.reuseIdentifier)
  }

  override func numberOfSections(in _: UITableView) -> Int {
    sections.count
  }

  override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
    let section = self.section(at: section)
    return section.tracks.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
    cell.configure(with: track(at: indexPath))
    return cell
  }

  override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    delegate?.tracksViewController(self, didSelect: track(at: indexPath))
  }

  override func tableView(_: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    UISwipeActionsConfiguration(actions: actions(at: indexPath))
  }

  @available(iOS 13.0, *)
  override func tableView(_: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
    UIContextMenuConfiguration(actions: actions(at: indexPath))
  }

  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: LabelTableHeaderFooterView.reuseIdentifier) as! LabelTableHeaderFooterView
    view.text = title(for: self.section(at: section))
    view.font = .fos_preferredFont(forTextStyle: .headline)
    view.textColor = .label
    return view
  }

  override func sectionIndexTitles(for _: UITableView) -> [String]? {
    sectionIndexItems.map(\.initial).map(String.init)
  }

  override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle _: String, at index: Int) -> Int {
    // HACK: UITableView only supports using section index titles pointing to
    // the first element of a given section. However here I want the indices to
    // point to arbitrary index paths. In order to achieve this here I am always
    // returning the first section as the target section for handling by
    // UITableView and preventing content offset updates by replacing
    // -[UIScrollView setContentOffset:] with an empty implementation. Compared
    // to the original table view, this implementation is missing prevention of
    // unnecessary haptic feedback responses when no movement should be
    // performed.
    let originalMethod = class_getInstanceMethod(UIScrollView.self, #selector(setter: UIScrollView.contentOffset))
    let swizzledMethod = class_getInstanceMethod(UIScrollView.self, #selector(setter: UIScrollView.fos_contentOffset))
    if let method1 = originalMethod, let method2 = swizzledMethod {
      method_exchangeImplementations(method1, method2)
      OperationQueue.main.addOperation { [weak self] in
        method_exchangeImplementations(method1, method2)

        if let self, let section = sections.firstIndex(where: { $0.sectionType == .all }) {
          feedbackGenerator.selectionChanged()

          let indexPath = IndexPath(row: sectionIndexItems[index].index, section: section)
          tableView.scrollToRow(at: indexPath, at: .top, animated: false)
        }
      }
    }

    return 0
  }
}

private extension TracksViewController {
  func section(at index: Int) -> Section {
    sections[index]
  }

  func track(at indexPath: IndexPath) -> Track {
    let section = section(at: indexPath.section)
    return section.tracks[indexPath.row].track
  }

  func actions(at indexPath: IndexPath) -> [Action] {
    guard let favoritesDelegate else { return [] }

    let track = track(at: indexPath)
    let action = favoritesDelegate.tracksViewController(self, canFavorite: track)
      ? Action(title: L10n.favorite, image: UIImage(systemName: "star.fill")) { [weak self] in
        guard let self else { return }
        self.favoritesDelegate?.tracksViewController(self, didFavorite: track)
      }
      : Action(title: L10n.unfavorite, image: UIImage(systemName: "star.slash.fill"), style: .destructive) { [weak self] in
        guard let self else { return }
        self.favoritesDelegate?.tracksViewController(self, didUnfavorite: track)
      }

    return [action]
  }

  func title(for section: Section) -> String? {
    switch section.sectionType {
    case .all:
      let filter = dataSource?.selectedFilter(in: self)
      return filter?.title
    case .favorites:
      return L10n.Search.Filter.favorites
    }
  }
}

extension TracksViewController.Item: Equatable, Hashable {
  static func == (_ lhs: Self, _ rhs: Self) -> Bool {
    lhs.track.name == rhs.track.name
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(track.name)
  }
}

extension UITableViewCell {
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
