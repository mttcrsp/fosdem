import UIKit

final class TrackTableViewCell: UITableViewCell {
    var roundsTopCorners: Bool {
        get { trackView.roundsTopCorners }
        set { trackView.roundsTopCorners = newValue; didChangeRoundsTopCorners() }
    }

    var roundsBottomCorners: Bool {
        get { trackView.roundsBottomCorners }
        set { trackView.roundsBottomCorners = newValue; didChangeRoundsBottomCorners() }
    }

    private let trackView = TrackTableViewCellContentView()
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

    private func didChangeRoundsTopCorners() {
        topConstraint.constant = roundsTopCorners ? 12 : 0
    }

    private func didChangeRoundsBottomCorners() {
        bottomConstraint.constant = roundsBottomCorners ? -12 : 0
    }
}
