import UIKit

protocol EventViewDelegate: AnyObject {
  func eventViewDidTapVideo(_ eventView: EventView)
  func eventViewDidTapLivestream(_ eventView: EventView)
  func eventView(_ eventView: EventView, didSelect attachment: Attachment)
}

final class EventView: UIStackView {
  weak var delegate: EventViewDelegate?

  var playbackPosition: PlaybackPosition = .beginning {
    didSet { didChangePlaybackPosition() }
  }

  var showsLivestream = false {
    didSet { didChangeShowLivestream() }
  }

  private weak var videoButton: RoundedButton?
  private weak var livestreamButton: RoundedButton?

  let event: Event

  init(event: Event) {
    self.event = event
    super.init(frame: .zero)

    spacing = 24
    axis = .vertical
    alignment = .leading

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
      videoButton.accessibilityLabel = L10n.Event.Video.Accessibility.begin
      videoButton.addTarget(self, action: videoAction, for: .touchUpInside)
      videoButton.titleLabel?.adjustsFontForContentSizeCategory = true
      self.videoButton = videoButton
      addArrangedSubview(videoButton)
      setCustomSpacing(28, after: videoButton)

      constraints.append(videoButton.widthAnchor.constraint(equalTo: widthAnchor))
    } else if event.links.contains(where: \.isLivestream) {
      let livestreamAction = #selector(didTapLivestream)
      let livestreamButton = RoundedButton()
      livestreamButton.accessibilityIdentifier = "livestream"
      livestreamButton.titleLabel?.adjustsFontForContentSizeCategory = true
      livestreamButton.addTarget(self, action: livestreamAction, for: .touchUpInside)
      livestreamButton.setTitle(L10n.Event.livestream, for: .normal)
      livestreamButton.isHidden = true
      self.livestreamButton = livestreamButton
      addArrangedSubview(livestreamButton)
      setCustomSpacing(28, after: livestreamButton)

      constraints.append(livestreamButton.widthAnchor.constraint(equalTo: widthAnchor))
    }

    if !event.people.isEmpty, let people = event.formattedPeople {
      let peopleView = EventMetadataView()
      peopleView.accessibilityLabel = L10n.Event.people(people)
      peopleView.image = .fos_systemImage(withName: "person.fill")
      peopleView.text = people
      addArrangedSubview(peopleView)
    }

    let roomView = EventMetadataView()
    roomView.accessibilityLabel = L10n.Event.room(event.room)
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
      attachmentsLabel.text = L10n.Event.attachments
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

    didChangePlaybackPosition()
    didChangeShowLivestream()
  }

  @available(*, unavailable)
  required init(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

private extension EventView {
  func didChangePlaybackPosition() {
    videoButton?.setTitle(playbackPosition.title, for: .normal)
    videoButton?.accessibilityLabel = playbackPosition.accessibilityLabel
    videoButton?.accessibilityIdentifier = playbackPosition.accessibilityIdentifier
  }

  private func didChangeShowLivestream() {
    livestreamButton?.isHidden = !showsLivestream
  }
}

private extension EventView {
  @objc func didTapLivestream() {
    delegate?.eventViewDidTapLivestream(self)
  }

  @objc func didTapVideo() {
    delegate?.eventViewDidTapVideo(self)
  }

  @objc func didTapAttachment(_ attachmentView: EventAttachmentView) {
    if let attachment = attachmentView.attachment {
      delegate?.eventView(self, didSelect: attachment)
    }
  }
}

private extension PlaybackPosition {
  var title: String {
    switch self {
    case .beginning:
      return L10n.Event.Video.begin
    case .end:
      return L10n.Event.Video.end
    case .at:
      return L10n.Event.Video.at
    }
  }

  var accessibilityLabel: String {
    switch self {
    case .beginning:
      return L10n.Event.Video.Accessibility.begin
    case .end:
      return L10n.Event.Video.Accessibility.end
    case .at:
      return L10n.Event.Video.Accessibility.at
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
