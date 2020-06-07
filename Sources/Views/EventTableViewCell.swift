import UIKit

final class EventTableViewCell: UITableViewCell {
  private let eventView = EventView()

  var dataSource: EventViewDataSource? {
    set { eventView.dataSource = newValue }
    get { eventView.dataSource }
  }

  var delegate: EventViewDelegate? {
    set { eventView.delegate = newValue }
    get { eventView.delegate }
  }

  init(isAdaptive: Bool) {
    super.init(style: .default, reuseIdentifier: nil)

    selectionStyle = .none
    contentView.addSubview(eventView)
    eventView.translatesAutoresizingMaskIntoConstraints = false

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

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(with event: Event) {
    eventView.event = event
  }

  func reloadPlaybackPosition() {
    eventView.reloadPlaybackPosition()
  }
}
