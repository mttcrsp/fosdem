import UIKit

final class EventAttachmentView: UIControl {
    var attachment: Attachment? {
        didSet { didChangeAttachment() }
    }

    private let label = UILabel()
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.font = .fos_preferredFont(forTextStyle: .body, withSymbolicTraits: [.traitItalic])

        imageView.contentMode = .center
        imageView.image = .fos_systemImage(withName: "arrow.down.circle")

        for subview in [imageView, label] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            addSubview(subview)
        }

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: -10),

            imageView.widthAnchor.constraint(equalToConstant: 20),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.centerYAnchor.constraint(equalTo: label.centerYAnchor),
        ])

        let highlightEvent: UIControl.Event = [.touchDown, .touchDragEnter]
        addTarget(self, action: #selector(didHighlight), for: highlightEvent)

        let unhighlightEvent: UIControl.Event = [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit]
        addTarget(self, action: #selector(didUnhighlight), for: unhighlightEvent)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class func canDisplay(_ attachment: Attachment) -> Bool {
        attachment.title != nil
    }

    @objc private func didHighlight() {
        alpha = 0.5
    }

    @objc private func didUnhighlight() {
        alpha = 1
    }

    private func didChangeAttachment() {
        label.text = attachment?.title
    }
}

private extension Attachment {
    var title: String? {
        switch (name, type.title) {
        case (nil, nil):
            return nil
        case (let value?, nil), (nil, let value?):
            return value
        case let (name?, type?):
            let lowercaseName = name.lowercased()
            let lowercaseType = type.lowercased()
            if lowercaseName.contains(lowercaseType) {
                return name
            } else {
                return "\(name) (\(type))"
            }
        }
    }
}

private extension AttachmentType {
    var title: String? {
        switch self {
        case .slides:
            return NSLocalizedString("attachment.slides", comment: "")
        case .audio:
            return NSLocalizedString("attachment.audio", comment: "")
        case .paper:
            return NSLocalizedString("attachment.paper", comment: "")
        case .video:
            return NSLocalizedString("attachment.video", comment: "")
        case .other:
            return nil
        }
    }
}
