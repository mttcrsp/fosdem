import UIKit

protocol EventViewDelegate: AnyObject {
  func eventViewDidTapVideo(_ eventView: EventView)
  func eventView(_ eventView: EventView, didSelect attachment: Attachment)
}

protocol EventViewDataSource: AnyObject {
  func eventView(_ eventView: EventView, playbackPositionFor event: Event) -> PlaybackPosition
}

final class EventView: UIStackView {
  weak var delegate: EventViewDelegate?
  weak var dataSource: EventViewDataSource? {
    didSet { reloadPlaybackPosition() }
  }

  private weak var videoButton: RoundedButton?

  var event: Event? {
    didSet { didChangeEvent() }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    spacing = 24
    axis = .vertical
    alignment = .leading
  }

  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func reloadPlaybackPosition() {
    var position: PlaybackPosition = .beginning
    if let dataSource = dataSource, let event = event {
      position = dataSource.eventView(self, playbackPositionFor: event)
    }

    videoButton?.setTitle(position.title, for: .normal)
    videoButton?.accessibilityLabel = position.accessibilityLabel
    videoButton?.accessibilityIdentifier = position.accessibilityIdentifier
  }

  private func didChangeEvent() {
    for subview in arrangedSubviews {
      removeArrangedSubview(subview)
      subview.removeFromSuperview()
    }

    guard let event = event else { return }

    var constraints: [NSLayoutConstraint] = []

    let titleLabel = UILabel()
    titleLabel.font = .fos_preferredFont(forTextStyle: .title1, withSymbolicTraits: .traitBold)
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.accessibilityTraits = .header
    titleLabel.text = event.title
    titleLabel.numberOfLines = 0
    addArrangedSubview(titleLabel)
    setCustomSpacing(18, after: titleLabel)

    let trackView = TrackView()
    trackView.track = event.track
    addArrangedSubview(trackView)
    setCustomSpacing(20, after: trackView)

    if event.video != nil {
      let videoAction = #selector(didTapVideo)
      let videoButton = RoundedButton()
      videoButton.accessibilityLabel = FOSLocalizedString("event.video.accessibility")
      videoButton.addTarget(self, action: videoAction, for: .touchUpInside)
      videoButton.titleLabel?.adjustsFontForContentSizeCategory = true
      self.videoButton = videoButton
      addArrangedSubview(videoButton)
      setCustomSpacing(28, after: videoButton)

      constraints.append(videoButton.widthAnchor.constraint(equalTo: widthAnchor))

      reloadPlaybackPosition()
    }

    if !event.people.isEmpty, let people = event.formattedPeople {
      let peopleView = EventMetadataView()
      peopleView.accessibilityLabel = FOSLocalizedString(format: "event.people", people)
      peopleView.image = .fos_systemImage(withName: "person.fill")
      peopleView.text = people
      addArrangedSubview(peopleView)
    }

    let roomView = EventMetadataView()
    roomView.accessibilityLabel = FOSLocalizedString(format: "event.room", event.room)
    roomView.image = .fos_systemImage(withName: "mappin.circle.fill")
    roomView.text = event.room
    addArrangedSubview(roomView)

    let dateView = EventMetadataView()
    dateView.image = .fos_systemImage(withName: "clock.fill")
    dateView.text = event.formattedDate
    addArrangedSubview(dateView)
    setCustomSpacing(28, after: dateView)

    if let subtitle = event.subtitle {
      let subtitleLabel = UILabel()
      subtitleLabel.font = .fos_preferredFont(forTextStyle: .headline)
      subtitleLabel.adjustsFontForContentSizeCategory = true
      subtitleLabel.numberOfLines = 0
      subtitleLabel.text = subtitle
      addArrangedSubview(subtitleLabel)
    }

    if let abstract = event.formattedAbstract {
      let abstractLabel = UILabel()
      abstractLabel.font = .fos_preferredFont(forTextStyle: .body)
      abstractLabel.adjustsFontForContentSizeCategory = true
      abstractLabel.numberOfLines = 0
      abstractLabel.text = abstract
      addArrangedSubview(abstractLabel)
    }

    if let summary = event.formattedSummary {
      let summaryLabel = UILabel()
      summaryLabel.font = .fos_preferredFont(forTextStyle: .body)
      summaryLabel.adjustsFontForContentSizeCategory = true
      summaryLabel.numberOfLines = 0
      summaryLabel.text = summary
      addArrangedSubview(summaryLabel)
    }

    let attachments = event.attachments.filter(EventAttachmentView.canDisplay)

    if !attachments.isEmpty {
      let attachmentsLabel = UILabel()
      attachmentsLabel.font = .fos_preferredFont(forTextStyle: .headline)
      attachmentsLabel.text = FOSLocalizedString("event.attachments")
      attachmentsLabel.adjustsFontForContentSizeCategory = true
      attachmentsLabel.numberOfLines = 0
      addArrangedSubview(attachmentsLabel)
      setCustomSpacing(22, after: attachmentsLabel)
    }

    for attachment in attachments {
      let attachmentAction = #selector(didTapAttachment(_:))
      let attachmentView = EventAttachmentView()
      attachmentView.attachment = attachment
      attachmentView.addTarget(self, action: attachmentAction, for: .touchUpInside)
      addArrangedSubview(attachmentView)

      constraints.append(attachmentView.widthAnchor.constraint(equalTo: widthAnchor))
    }

    accessibilityElements = subviews

    NSLayoutConstraint.activate(constraints)
  }

  @objc private func didTapVideo() {
    delegate?.eventViewDidTapVideo(self)
  }

  @objc private func didTapAttachment(_ attachmentView: EventAttachmentView) {
    if let attachment = attachmentView.attachment {
      delegate?.eventView(self, didSelect: attachment)
    }
  }
}

private extension PlaybackPosition {
  var title: String {
    switch self {
    case .beginning:
      return FOSLocalizedString("event.video.begin")
    case .end:
      return FOSLocalizedString("event.video.end")
    case .at:
      return FOSLocalizedString("event.video.at")
    }
  }

  var accessibilityLabel: String {
    switch self {
    case .beginning:
      return FOSLocalizedString("event.video.accessibility.begin")
    case .end:
      return FOSLocalizedString("event.video.accessibility.end")
    case .at:
      return FOSLocalizedString("event.video.accessibility.at")
    }
  }

  var accessibilityIdentifier: String {
    switch self {
    case .beginning:
      return "play"
    case .end:
      return "replay"
    case .at:
      return "resume"
    }
  }
}
