import UIKit

protocol EventViewDelegate: AnyObject {
  func eventViewDidTapVideo(_ eventView: EventView)
  func eventViewDidTapLivestream(_ eventView: EventView)
  func eventView(_ eventView: EventView, didSelect url: URL)
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
  private weak var livestreamButton: RoundedButton?

  var event: Event? {
    didSet { didChangeEvent() }
  }

  var showsLivestream = false {
    didSet { didChangeShowLivestream() }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    spacing = 24
    axis = .vertical
    alignment = .leading
  }

  @available(*, unavailable)
  required init(coder _: NSCoder) {
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
      videoButton.accessibilityLabel = L10n.Event.Video.Accessibility.begin
      videoButton.addTarget(self, action: videoAction, for: .touchUpInside)
      videoButton.titleLabel?.adjustsFontForContentSizeCategory = true
      self.videoButton = videoButton
      addArrangedSubview(videoButton)
      setCustomSpacing(28, after: videoButton)

      constraints.append(videoButton.widthAnchor.constraint(equalTo: widthAnchor))

      reloadPlaybackPosition()
    } else if showsLivestream {
      let livestreamAction = #selector(didTapLivestream)
      let livestreamButton = RoundedButton()
      livestreamButton.accessibilityIdentifier = "livestream"
      livestreamButton.titleLabel?.adjustsFontForContentSizeCategory = true
      livestreamButton.addTarget(self, action: livestreamAction, for: .touchUpInside)
      livestreamButton.setTitle(L10n.Event.livestream, for: .normal)
      self.livestreamButton = livestreamButton
      addArrangedSubview(livestreamButton)
      setCustomSpacing(28, after: livestreamButton)

      constraints.append(livestreamButton.widthAnchor.constraint(equalTo: widthAnchor))
    }

    if !event.people.isEmpty, let people = event.formattedPeople {
      let peopleView = EventMetadataView()
      peopleView.accessibilityLabel = L10n.Event.people(people)
      peopleView.image = UIImage(systemName: "person.fill")
      peopleView.text = people
      addArrangedSubview(peopleView)
    }

    let roomView = EventMetadataView()
    roomView.accessibilityLabel = L10n.Event.room(event.room)
    roomView.image = UIImage(systemName: "mappin.circle.fill")
    roomView.text = event.room
    addArrangedSubview(roomView)

    let dateView = EventMetadataView()
    dateView.image = UIImage(systemName: "clock.fill")
    dateView.text = event.formattedDate
    addArrangedSubview(dateView)
    setCustomSpacing(28, after: dateView)

    if let abstract = event.formattedAbstract {
      let subtitleLabel = UILabel()
      subtitleLabel.font = .fos_preferredFont(forTextStyle: .headline)
      subtitleLabel.adjustsFontForContentSizeCategory = true
      subtitleLabel.numberOfLines = 0
      subtitleLabel.text = event.subtitle ?? L10n.Event.abstract
      addArrangedSubview(subtitleLabel)

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

    let groups: [EventAdditionsGroup] = [
      .init(links: event.links),
      .init(attachments: event.attachments),
    ]

    for group in groups {
      if !group.items.isEmpty {
        let groupLabel = UILabel()
        groupLabel.font = .fos_preferredFont(forTextStyle: .headline)
        groupLabel.text = group.title
        groupLabel.adjustsFontForContentSizeCategory = true
        groupLabel.numberOfLines = 0
        addArrangedSubview(groupLabel)
        setCustomSpacing(22, after: groupLabel)
      }

      for item in group.items {
        let itemAction = #selector(didTapAdditionalItem(_:))
        let itemView = EventAdditionsItemView()
        itemView.item = item
        itemView.group = group
        itemView.addTarget(self, action: itemAction, for: .touchUpInside)
        addArrangedSubview(itemView)

        constraints.append(itemView.widthAnchor.constraint(equalTo: widthAnchor))
      }
    }

    accessibilityElements = subviews

    NSLayoutConstraint.activate(constraints)
  }

  private func didChangeShowLivestream() {
    livestreamButton?.isHidden = !showsLivestream
  }

  @objc private func didTapLivestream() {
    delegate?.eventViewDidTapLivestream(self)
  }

  @objc private func didTapVideo() {
    delegate?.eventViewDidTapVideo(self)
  }

  @objc private func didTapAdditionalItem(_ itemView: EventAdditionsItemView) {
    if let item = itemView.item {
      delegate?.eventView(self, didSelect: item.url)
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
