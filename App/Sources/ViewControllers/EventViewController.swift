import UIKit

/// @mockable
protocol EventViewControllerDelegate: AnyObject {
  func eventViewControllerDidTapVideo(_ eventViewController: EventViewController)
  func eventViewControllerDidTapLivestream(_ eventViewController: EventViewController)
  func eventViewController(_ eventViewController: EventViewController, didSelect url: URL)
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

  var showsLivestream: Bool {
    get { eventCell.showsLivestream }
    set { eventCell.showsLivestream = newValue }
  }

  func reloadPlaybackPosition() {
    eventCell.reloadPlaybackPosition()
  }

  private lazy var eventCell: EventTableViewCell = {
    let cell = EventTableViewCell(isAdaptive: isAdaptive)
    cell.delegate = self
    cell.dataSource = self
    return cell
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
    if tableView.style == .insetGrouped {
      return false
    } else {
      return true
    }
  }

  private func eventChanged() {
    if isViewLoaded {
      tableView.reloadData()
    }

    if let event = event {
      eventCell.configure(with: event)
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

  func eventView(_: EventView, didSelect url: URL) {
    delegate?.eventViewController(self, didSelect: url)
  }

  func eventView(_: EventView, playbackPositionFor event: Event) -> PlaybackPosition {
    dataSource?.eventViewController(self, playbackPositionFor: event) ?? .beginning
  }
}
