import UIKit

final class TracksTableViewCell: UITableViewCell {
    var position: TracksTableViewCellContentView.Position {
        get { trackView.position }
        set { trackView.position = newValue; didChangePosition() }
    }

    private let trackView = TracksTableViewCellContentView()
    private lazy var topConstraint = trackView.topAnchor.constraint(equalTo: contentView.topAnchor)
    private lazy var bottomConstraint = trackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectedBackgroundView = UIView()
        contentView.addSubview(trackView)
        trackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            topConstraint, bottomConstraint,
            trackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            trackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        trackView.setHighlighted(highlighted, animated: animated)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        trackView.setSelected(selected, animated: animated)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with track: Track) {
        trackView.configure(with: track)
    }

    private func didChangePosition() {
        topConstraint.constant = position.topConstraintConstant
        bottomConstraint.constant = position.bottomConstraintConstant
    }
}

private extension TracksTableViewCellContentView.Position {
    var topConstraintConstant: CGFloat {
        switch self {
        case .top: return 16
        case .mid, .bottom: return 0
        }
    }

    var bottomConstraintConstant: CGFloat {
        switch self {
        case .bottom: return -16
        case .top, .mid: return 0
        }
    }
}
