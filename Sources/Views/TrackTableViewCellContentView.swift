import UIKit

final class TrackTableViewCellContentView: UIView {
    var roundsTopCorners = false {
        didSet { didChangeRoundsTopCorners() }
    }

    var roundsBottomCorners = false {
        didSet { didChangeRoundsBottomCorners() }
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

    private var roundedCorners: UIRectCorner {
        var corners: UIRectCorner = []

        if roundsTopCorners {
            corners.formUnion(.topLeft)
            corners.formUnion(.topRight)
        }

        if roundsBottomCorners {
            corners.formUnion(.bottomLeft)
            corners.formUnion(.bottomRight)
        }

        return corners
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

    override func layoutSubviews() {
        super.layoutSubviews()

        let cornerRadii = CGSize(width: 10, height: 10)
        let path = UIBezierPath(roundedRect: containerView.bounds, byRoundingCorners: roundedCorners, cornerRadii: cornerRadii)
        maskLayer.path = path.cgPath
        maskLayer.frame = containerView.bounds
        containerView.layer.mask = maskLayer

        selectedContainerView.frame = containerView.bounds
    }

    override func updateConstraints() {
        super.updateConstraints()

        if #available(iOS 11.0, *) {
            let metrics = UIFontMetrics.default
            indicatorImageViewWidth.constant = metrics.scaledValue(for: 11)
            indicatorImageViewHeight.constant = metrics.scaledValue(for: 14)
        }
    }

    private func didChangeRoundsTopCorners() {
        setNeedsLayout()
    }

    private func didChangeRoundsBottomCorners() {
        separatorView.isHidden = roundsBottomCorners
        setNeedsLayout()
    }
}
