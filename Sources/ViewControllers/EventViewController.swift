import UIKit

/// @mockable
protocol EventViewControllerListener: AnyObject {
  func eventViewControllerDidTapVideo(_ eventViewController: EventViewController)
  func eventViewControllerDidTapLivestream(_ eventViewController: EventViewController)
  func eventViewController(_ eventViewController: EventViewController, didSelect attachment: Attachment)
}

class EventViewController: UITableViewController {
  weak var eventListener: EventViewControllerListener?

  var playbackPosition: PlaybackPosition {
    get { eventCell.playbackPosition }
    set { eventCell.playbackPosition = newValue }
  }

  var showsLivestream: Bool {
    get { eventCell.showsLivestream }
    set { eventCell.showsLivestream = newValue }
  }

  private lazy var eventCell: EventTableViewCell = {
    let eventCell = EventTableViewCell(event: event, isAdaptive: isAdaptive)
    eventCell.delegate = self
    return eventCell
  }()

  var event: Event

  init(event: Event) {
    self.event = event

    super.init(style: {
      if #available(iOS 13.0, *), UIDevice.current.userInterfaceIdiom == .pad {
        return .insetGrouped
      } else {
        return .plain
      }
    }())
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension EventViewController {
  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.separatorStyle = .none
    tableView.accessibilityIdentifier = "event"
    if isAdaptive {
      tableView.contentInset.top = 8
      tableView.contentInset.bottom = 20
    }
  }
}

extension EventViewController {
  override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    1
  }

  override func tableView(_: UITableView, cellForRowAt _: IndexPath) -> UITableViewCell {
    eventCell
  }
}

extension EventViewController: EventViewDelegate {
  func eventViewDidTapLivestream(_: EventView) {
    eventListener?.eventViewControllerDidTapLivestream(self)
  }

  func eventViewDidTapVideo(_: EventView) {
    eventListener?.eventViewControllerDidTapVideo(self)
  }

  func eventView(_: EventView, didSelect attachment: Attachment) {
    eventListener?.eventViewController(self, didSelect: attachment)
  }
}

private extension EventViewController {
  var isAdaptive: Bool {
    if #available(iOS 13.0, *), tableView.style == .insetGrouped {
      return false
    } else {
      return true
    }
  }
}
