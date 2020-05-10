import UIKit

final class EventTrackView: UIView {
    var track: String? {
        get { trackView.track }
        set { trackView.track = newValue }
    }

    private let trackView = TrackView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(trackView)

        trackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            trackView.topAnchor.constraint(equalTo: topAnchor),
            trackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            trackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trackView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor),
        ])
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
