import UIKit

final class TrackTableViewCell: UITableViewCell {
    var track: String? {
        didSet { didChangeTrack() }
    }

    private lazy var trackView = TrackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        selectionStyle = .none

        contentView.addSubview(trackView)

        trackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            trackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            trackView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            trackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            trackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.trailingAnchor),
        ])
    }

    private func didChangeTrack() {
        if let track = track {
            let format = NSLocalizedString("event.track", comment: "")
            let string = String(format: format, track)
            trackView.track = track
            accessibilityLabel = string
        } else {
            trackView.track = nil
            accessibilityLabel = nil
        }
    }
}
