import UIKit

final class EventsViewController: UITableViewController {
  var events: [Event] = [] {
    didSet { didChangeEvents() }
  }

  var onEventTap: ((Event) -> Void)?

  enum CaptionStyle {
    case agenda
    case soon
  }

  var captionStyle = CaptionStyle.agenda
  private var captions: [Event: String] = [:]

  struct Favoriting {
    var isFavorite: (Event) -> Bool
    var onFavoriteTap: (Event) -> Void
    var onUnfavoriteTap: (Event) -> Void
  }

  var favoriting: Favoriting?

  struct LiveDisplaying {
    var isLive: (Event) -> Bool
  }

  var liveDisplaying: LiveDisplaying?

  struct Deleting {
    var onDelete: (Event) -> Void
  }

  var deleting: Deleting?

  var emptyBackgroundTitle: String? {
    get { emptyBackgroundView.title }
    set { emptyBackgroundView.title = newValue }
  }

  var emptyBackgroundMessage: String? {
    get { emptyBackgroundView.message }
    set { emptyBackgroundView.message = newValue }
  }

  private lazy var emptyBackgroundView = TableBackgroundView()

  func reloadData() {
    if isViewLoaded {
      tableView.reloadData()
    }
  }

  func beginUpdates() {
    tableView.beginUpdates()
  }

  func endUpdates() {
    tableView.endUpdates()
  }

  func insertEvent(at index: Int) {
    let section = IndexSet([index])
    tableView.insertSections(section, with: .fade)
  }

  func deleteEvent(at index: Int) {
    let section = IndexSet([index])
    tableView.deleteSections(section, with: .fade)
  }

  func reloadLiveStatus() {
    guard viewIfLoaded?.window != nil else { return }

    var indexPaths: [IndexPath] = []

    for indexPath in tableView.indexPathsForVisibleRows ?? [] {
      if let cell = tableView.cellForRow(at: indexPath) {
        let event = self.event(forSection: indexPath.section)
        let oldStatus = cell.showsLiveIndicator
        let newStatus = shouldShowLiveIndicator(for: event)

        if oldStatus != newStatus {
          indexPaths.append(indexPath)
        }
      }
    }

    tableView.reloadRows(at: indexPaths, with: .fade)
  }

  func select(_ event: Event) {
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
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    let count = events.count
    let isEmpty = count == 0
    tableView.isUserInteractionEnabled = !isEmpty
    tableView.backgroundView = isEmpty ? emptyBackgroundView : nil
    return count
  }

  override func tableView(_ tableView: UITableView, viewForHeaderInSection _: Int) -> UIView? {
    let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: LabelTableHeaderFooterView.reuseIdentifier) as! LabelTableHeaderFooterView
    // view.text = event(forSection: section).caption
    return view
  }

  override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    1
  }

  override func tableView(_: UITableView, commit _: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    deleting?.onDelete(event(forSection: indexPath.section))
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let event = event(forSection: indexPath.section)
    let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
    cell.showsLiveIndicator = shouldShowLiveIndicator(for: event)
    cell.configure(with: event)
    return cell
  }

  override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    onEventTap?(event(forSection: indexPath.section))
  }

  override func tableView(_: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    UISwipeActionsConfiguration(actions: actions(at: indexPath))
  }

  @available(iOS 13.0, *)
  override func tableView(_: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
    UIContextMenuConfiguration(actions: actions(at: indexPath))
  }

  private func actions(at indexPath: IndexPath) -> [Action] {
    guard let favoriting else {
      return []
    }

    let event = event(forSection: indexPath.section)

    if favoriting.isFavorite(event) {
      let title = L10n.Event.add
      let image = UIImage(systemName: "calendar.badge.plus")
      return [Action(title: title, image: image) {
        favoriting.onFavoriteTap(event)
      }]
    } else {
      let title = L10n.Event.remove
      let image = UIImage(systemName: "calendar.badge.minus")
      return [Action(title: title, image: image, style: .destructive) {
        favoriting.onUnfavoriteTap(event)
      }]
    }
  }

  private func event(forSection section: Int) -> Event {
    events[section]
  }

  private func shouldShowLiveIndicator(for event: Event) -> Bool {
    liveDisplaying?.isLive(event) ?? false
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

extension [Event] {
  var agendaCaptions: [Event: String] {
    var captions: [Event: String] = [:]
    for event in self {
      captions[event] = [event.formattedStart, event.room, event.track]
        .compactMap { $0 }
        .joined(separator: Self.separator)
    }
    return captions
  }

  var soonCaptions: [Event: String] {
    var captions: [Event: String] = [:]
    for event in self {
      captions[event] = [event.formattedStart, event.room]
        .compactMap { $0 }
        .joined(separator: Self.separator)
    }
    return captions
  }

  private static let separator = " - "
}
