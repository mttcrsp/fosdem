import UIKit

final class EventTableViewCell: UITableViewCell {
  var delegate: EventViewDelegate? {
    get { eventView.delegate }
    set { eventView.delegate = newValue }
  }

  var playbackPosition: PlaybackPosition {
    get { eventView.playbackPosition }
    set { eventView.playbackPosition = newValue }
  }

  var showsLivestream: Bool {
    get { eventView.showsLivestream }
    set { eventView.showsLivestream = newValue }
  }

  private let eventView: EventView

  init(event: Event, isAdaptive: Bool) {
    eventView = EventView(event: event)
    eventView.translatesAutoresizingMaskIntoConstraints = false

    super.init(style: .default, reuseIdentifier: nil)

    selectionStyle = .none
    isAccessibilityElement = false
    contentView.addSubview(eventView)

    if isAdaptive {
      let defaultWidthConstraint = eventView.widthAnchor.constraint(equalTo: contentView.widthAnchor)
      defaultWidthConstraint.priority = .defaultHigh

      let maxWidthConstraint = eventView.widthAnchor.constraint(lessThanOrEqualToConstant: 500)

      NSLayoutConstraint.activate([
        maxWidthConstraint,
        defaultWidthConstraint,
        eventView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
        eventView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
        eventView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
        eventView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.layoutMarginsGuide.leadingAnchor),
        eventView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.trailingAnchor),
      ])
    } else {
      NSLayoutConstraint.activate([
        eventView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
        eventView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
        eventView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
        eventView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      ])
    }
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
