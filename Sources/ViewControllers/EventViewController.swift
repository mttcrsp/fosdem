import UIKit

/// @mockable
protocol EventViewControllerDelegate: AnyObject {
  func eventViewControllerDidTapVideo(_ eventViewController: EventViewController)
  func eventViewControllerDidTapFavorite(_ eventViewController: EventViewController)
  func eventViewControllerDidTapUnfavorite(_ eventViewController: EventViewController)
  func eventViewControllerDidTapLivestream(_ eventViewController: EventViewController)
  func eventViewController(_ eventViewController: EventViewController, didSelect attachment: Attachment)
}

/// @mockable
protocol EventViewControllerDataSource: AnyObject {
  func eventViewController(_ eventViewController: EventViewController, playbackPositionFor event: Event) -> PlaybackPosition
}

final class EventViewController: UITableViewController {
  weak var delegate: EventViewControllerDelegate?
  weak var dataSource: EventViewControllerDataSource?

  var event: Event? {
    didSet { eventChanged() }
  }

  var showsLivestream = false

  var showsFavoriteEvent = false {
    didSet { showsFavoriteEventChanged() }
  }

  var showsFavoriteButton: Bool {
    get { navigationItem.rightBarButtonItem != nil }
    set { navigationItem.rightBarButtonItem = newValue ? favoriteButton : nil }
  }

  func reloadPlaybackPosition() {
    eventCell.reloadPlaybackPosition()
  }

  private lazy var eventCell: EventTableViewCell = {
    let cell = EventTableViewCell(isAdaptive: isAdaptive)
    cell.delegate = self
    cell.dataSource = self
    cell.showsLivestream = showsLivestream
    return cell
  }()

  private lazy var favoriteButton: UIBarButtonItem = {
    let button = UIBarButtonItem(title: favoriteButtonTitle, style: .plain, target: self, action: #selector(didTapFavorite))
    button.accessibilityIdentifier = favoriteButtonIdentifier
    return button
  }()

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.separatorStyle = .none
    tableView.accessibilityIdentifier = "event"

    if isAdaptive {
      tableView.contentInset.top = 8
      tableView.contentInset.bottom = 20
    }
  }

  override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    event == nil ? 0 : 1
  }

  override func tableView(_: UITableView, cellForRowAt _: IndexPath) -> UITableViewCell {
    eventCell
  }

  private var isAdaptive: Bool {
    if #available(iOS 13.0, *), tableView.style == .insetGrouped {
      return false
    } else {
      return true
    }
  }

  private var favoriteButtonTitle: String {
    showsFavoriteEvent ? L10n.Event.remove : L10n.Event.add
  }

  private var favoriteButtonIdentifier: String {
    showsFavoriteEvent ? "unfavorite" : "favorite"
  }

  private func eventChanged() {
    if isViewLoaded {
      tableView.reloadData()
    }

    if let event = event {
      eventCell.configure(with: event)
    }
  }

  private func showsFavoriteEventChanged() {
    favoriteButton.title = favoriteButtonTitle
    favoriteButton.accessibilityIdentifier = favoriteButtonIdentifier
  }

  @objc private func didTapFavorite() {
    if showsFavoriteEvent {
      delegate?.eventViewControllerDidTapUnfavorite(self)
    } else {
      delegate?.eventViewControllerDidTapFavorite(self)
    }
  }
}

extension EventViewController: EventViewDelegate, EventViewDataSource {
  func eventViewDidTapLivestream(_: EventView) {
    delegate?.eventViewControllerDidTapLivestream(self)
  }

  func eventViewDidTapVideo(_: EventView) {
    delegate?.eventViewControllerDidTapVideo(self)
  }

  func eventView(_: EventView, didSelect attachment: Attachment) {
    delegate?.eventViewController(self, didSelect: attachment)
  }

  func eventView(_: EventView, playbackPositionFor event: Event) -> PlaybackPosition {
    dataSource?.eventViewController(self, playbackPositionFor: event) ?? .beginning
  }
}
