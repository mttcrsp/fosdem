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

    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reloadPlaybackPosition() {
        if let event = event {
            let videoTitle = makeVideoTitle(for: event)
            videoButton?.setTitle(videoTitle, for: .normal)
        }
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
        titleLabel.text = event.title
        titleLabel.numberOfLines = 0
        addArrangedSubview(titleLabel)
        setCustomSpacing(18, after: titleLabel)

        let trackView = TrackView()
        trackView.track = event.track
        addArrangedSubview(trackView)
        setCustomSpacing(20, after: trackView)

        if event.video != nil {
            let videoTitle = makeVideoTitle(for: event)
            let videoAction = #selector(didTapVideo)
            let videoButton = RoundedButton()
            videoButton.accessibilityLabel = NSLocalizedString("event.video.accessibility", comment: "")
            videoButton.addTarget(self, action: videoAction, for: .touchUpInside)
            videoButton.titleLabel?.adjustsFontForContentSizeCategory = true
            videoButton.setTitle(videoTitle, for: .normal)
            self.videoButton = videoButton
            addArrangedSubview(videoButton)
            setCustomSpacing(28, after: videoButton)

            constraints.append(videoButton.widthAnchor.constraint(equalTo: widthAnchor))
        }

        if !event.people.isEmpty {
            let peopleView = EventMetadataView()
            peopleView.image = .fos_systemImage(withName: "person.fill")
            peopleView.text = event.formattedPeople

            if let people = event.formattedPeople {
                let accessibilityFormat = NSLocalizedString("event.people", comment: "")
                let accessibilityLabel = String(format: accessibilityFormat, people)
                peopleView.accessibilityLabel = accessibilityLabel
            }

            addArrangedSubview(peopleView)
        }

        let roomFormat = NSLocalizedString("event.room", comment: "")
        let roomLabel = String(format: roomFormat, event.room)

        let roomView = EventMetadataView()
        roomView.image = .fos_systemImage(withName: "mappin.circle.fill")
        roomView.accessibilityLabel = roomLabel
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
            attachmentsLabel.text = NSLocalizedString("event.attachments", comment: "")
            attachmentsLabel.font = .fos_preferredFont(forTextStyle: .headline)
            attachmentsLabel.adjustsFontForContentSizeCategory = true
            attachmentsLabel.numberOfLines = 0
            addArrangedSubview(attachmentsLabel)
            setCustomSpacing(22, after: attachmentsLabel)
        }

        for attachment in attachments {
            let attachmentAction = #selector(didTapAttachment(_:))
            let attachmentView = EventAttachmentView()
            attachmentView.accessibilityTraits = .link
            attachmentView.attachment = attachment
            attachmentView.addTarget(self, action: attachmentAction, for: .touchUpInside)
            addArrangedSubview(attachmentView)

            constraints.append(attachmentView.widthAnchor.constraint(equalTo: widthAnchor))
        }

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

    private func makeVideoTitle(for event: Event) -> String {
        let position = dataSource?.eventView(self, playbackPositionFor: event)
        switch position ?? .beginning {
        case .beginning: return NSLocalizedString("event.video.begin", comment: "")
        case .end: return NSLocalizedString("event.video.end", comment: "")
        case .at: return NSLocalizedString("event.video.at", comment: "")
        }
    }
}
