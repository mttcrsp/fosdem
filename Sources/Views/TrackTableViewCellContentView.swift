import UIKit

final class TrackTableViewCellContentView: UIView {
    enum Position { case top, mid, bottom }

    var position: Position = .mid {
        didSet { didChangePosition() }
    }

    private let nameLabel = UILabel()
    private let indicatorImageView = UIImageView()
    private let containerView = UIView()
    private let separatorView = UIView()
    private let maskLayer = CAShapeLayer()
    private let selectedContainerView = UIView()

    private lazy var indicatorImageViewWidth = indicatorImageView.widthAnchor.constraint(equalToConstant: 11)
    private lazy var indicatorImageViewHeight = indicatorImageView.heightAnchor.constraint(equalToConstant: 14)

    override init(frame: CGRect) {
        super.init(frame: frame)

        separatorView.backgroundColor = .fos_separator
        selectedContainerView.backgroundColor = .fos_systemGray4
        containerView.backgroundColor = .fos_secondarySystemGroupedBackground

        nameLabel.numberOfLines = 0
        nameLabel.textColor = .fos_label
        nameLabel.font = .fos_preferredFont(forTextStyle: .body)
        indicatorImageView.image = UIImage(named: "chevron.right")

        for subview in [containerView, separatorView] {
            addSubview(subview)
        }

        for subview in [selectedContainerView, nameLabel, indicatorImageView] {
            containerView.addSubview(subview)
        }

        for subview in [containerView, separatorView, nameLabel, indicatorImageView] {
            subview.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            containerView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),

            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            nameLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),

            indicatorImageViewWidth, indicatorImageViewHeight,
            indicatorImageView.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            indicatorImageView.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 16),
            indicatorImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            separatorView.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1 / traitCollection.displayScale),
        ])
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with track: Track) {
        nameLabel.text = track.name
    }

    func setHighlighted(_ highlighted: Bool, animated: Bool) {
        setSelected(highlighted, animated: animated)
    }

    func setSelected(_ selected: Bool, animated _: Bool) {
        UIView.animate(withDuration: 0) { [weak self] in
            self?.selectedContainerView.alpha = selected ? 1 : 0
        }
    }

    override func updateConstraints() {
        super.updateConstraints()

        if #available(iOS 11.0, *) {
            let metrics = UIFontMetrics.default
            indicatorImageViewWidth.constant = metrics.scaledValue(for: 11)
            indicatorImageViewHeight.constant = metrics.scaledValue(for: 14)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let cornerRadii = CGSize(width: 10, height: 10)
        let path = UIBezierPath(roundedRect: containerView.bounds, byRoundingCorners: position.corners, cornerRadii: cornerRadii)
        maskLayer.path = path.cgPath
        maskLayer.frame = containerView.bounds
        containerView.layer.mask = maskLayer

        selectedContainerView.frame = containerView.bounds
    }

    private func didChangePosition() {
        separatorView.isHidden = !position.showsSeparatorView
    }
}

private extension TrackTableViewCellContentView.Position {
    var showsSeparatorView: Bool {
        switch self {
        case .bottom: return false
        case .top, .mid: return true
        }
    }

    var corners: UIRectCorner {
        switch self {
        case .mid: return []
        case .top: return [.topLeft, .topRight]
        case .bottom: return [.bottomLeft, .bottomRight]
        }
    }
}
