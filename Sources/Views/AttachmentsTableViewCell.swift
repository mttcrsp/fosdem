import UIKit

protocol AttachmentsTableViewCellDelegate: AnyObject {
    func attachmentCell(_ attachmentCell: AttachmentsTableViewCell, didSelect attachment: Attachment)
}

final class AttachmentsTableViewCell: UITableViewCell {
    weak var delegate: AttachmentsTableViewCellDelegate?

    var attachments: [Attachment] = [] {
        didSet { didChangeAttachments() }
    }

    private let stackView = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        let headerLabel = UILabel()
        headerLabel.numberOfLines = 0
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.font = .fos_preferredFont(forTextStyle: .headline)
        headerLabel.text = NSLocalizedString("event.attachments", comment: "")

        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stackView)
        contentView.addSubview(headerLabel)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            headerLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),

            stackView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: headerLabel.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: headerLabel.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        attachments = []
    }

    @objc private func didTapButton(_ button: UIButton) {
        if let index = stackView.arrangedSubviews.firstIndex(of: button) {
            delegate?.attachmentCell(self, didSelect: attachments[index])
        }
    }

    func didChangeAttachments() {
        for subview in stackView.arrangedSubviews {
            subview.removeFromSuperview()
            stackView.removeArrangedSubview(subview)
        }

        for attachment in attachments {
            let subview = makeButton(for: attachment)
            stackView.addArrangedSubview(subview)
        }

        setNeedsLayout()
        layoutIfNeeded()
    }

    private func makeButton(for attachment: Attachment) -> UIButton {
        let button = UIButton()
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .natural
        button.setTitleColor(.fos_label, for: .normal)
        button.setTitle(attachment.title, for: .normal)
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        return button
    }
}

private extension Attachment {
    var title: String? {
        switch (name, type.title) {
        case let (name?, type?): return "\(name) (\(type))"
        case (let name?, nil), (nil, let name?): return name
        case (nil, nil): return nil
        }
    }
}

private extension AttachmentType {
    var title: String? {
        switch self {
        case .slides: return NSLocalizedString("attachment.slides", comment: "")
        case .audio: return NSLocalizedString("attachment.audio", comment: "")
        case .paper: return NSLocalizedString("attachment.paper", comment: "")
        case .video: return NSLocalizedString("attachment.video", comment: "")
        case .other: return nil
        }
    }
}
