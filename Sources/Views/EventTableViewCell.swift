import UIKit

final class EventTableViewCell: UITableViewCell {
    private var observer: NSObjectProtocol?

    private let titleLabel = UILabel()
    private let metadataLabel = UILabel()
    private lazy var contentStackView = UIStackView(arrangedSubviews: [metadataLabel, titleLabel])
    private lazy var contentStackViewTopConstraint = contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: contentInsets.top)
    private lazy var contentStackViewBottomConstraint = contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -contentInsets.bottom)
    private lazy var contentStackViewLeadingConstraint = contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: contentInsets.left)
    private lazy var contentStackViewTrailingConstraint = contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -contentInsets.right)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        accessoryType = .disclosureIndicator

        selectedBackgroundView = .init()
        selectedBackgroundView?.backgroundColor = selectedBackgroundColor
        selectedBackgroundView?.layer.mask = CAShapeLayer()

        titleLabel.font = .fos_preferredFont(forTextStyle: .headline)
        titleLabel.numberOfLines = 0

        metadataLabel.font = .fos_preferredFont(forTextStyle: .subheadline)
        metadataLabel.textColor = .fos_secondaryLabel
        metadataLabel.numberOfLines = 0

        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.spacing = contentSpacing
        contentStackView.axis = .vertical

        contentView.addSubview(contentStackView)

        NSLayoutConstraint.activate([
            contentStackViewTopConstraint,
            contentStackViewBottomConstraint,
            contentStackViewLeadingConstraint,
            contentStackViewTrailingConstraint,
        ])

        let notificationCenter = NotificationCenter.default
        let notificationName = UIContentSizeCategory.didChangeNotification
        observer = notificationCenter.addObserver(forName: notificationName, object: nil, queue: nil) { [weak self] _ in
            self?.contentSizeCategoryDidChange()
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var contentSpacing: CGFloat {
        makeScaledValue(for: 4)
    }

    private var contentInsets: UIEdgeInsets {
        let inset = makeScaledValue(for: 16)
        return .init(top: inset, left: inset, bottom: inset, right: inset)
    }

    private var selectedBackgroundInsets: UIEdgeInsets {
        var insets = UIEdgeInsets()
        insets.top = contentInsets.top / 2
        insets.left = contentInsets.left / 2
        insets.right = contentInsets.right / 2
        insets.bottom = contentInsets.bottom / 2
        return insets
    }

    private var selectedBackgroundColor: UIColor {
        tintColor.withAlphaComponent(0.1)
    }

    func configure(with event: Event) {
        titleLabel.text = event.title
        metadataLabel.text = event.formattedStartAndRoom
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if let mask = selectedBackgroundView?.layer.mask as? CAShapeLayer {
            let backgroundRect = bounds.inset(by: selectedBackgroundInsets)
            let backgroundPath = UIBezierPath(roundedRect: backgroundRect, cornerRadius: 8)
            mask.path = backgroundPath.cgPath
        }
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        selectedBackgroundView?.backgroundColor = selectedBackgroundColor
    }

    private func contentSizeCategoryDidChange() {
        contentStackView.spacing = contentSpacing

        let insets = contentInsets
        contentStackViewTopConstraint.constant = insets.top
        contentStackViewBottomConstraint.constant = insets.bottom
        contentStackViewLeadingConstraint.constant = insets.left
        contentStackViewTrailingConstraint.constant = insets.right
    }

    private func makeScaledValue(for value: CGFloat) -> CGFloat {
        if #available(iOS 11.0, *) {
            return UIFontMetrics.default.scaledValue(for: value)
        } else {
            return value
        }
    }
}

private extension Event {
    var formattedStartAndRoom: String {
        guard let formattedStart = formattedStart else { return room }
        return "\(formattedStart) - \(room)"
    }
}
