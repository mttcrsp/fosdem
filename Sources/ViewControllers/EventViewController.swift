import UIKit

protocol EventViewControllerDelegate: AnyObject {
    func eventViewControllerDidTapVideo(_ eventViewController: EventViewController)
    func eventViewController(_ eventViewController: EventViewController, didSelect attachment: Attachment)
}

protocol EventViewControllerDataSource: AnyObject {
    func eventViewController(_ eventViewController: EventViewController, playbackPositionFor event: Event) -> PlaybackPosition
}

final class EventViewController: UIViewController {
    weak var delegate: EventViewControllerDelegate?
    weak var dataSource: EventViewControllerDataSource?

    var event: Event?

    private lazy var eventView = EventView()
    private lazy var scrollView = UIScrollView()

    func reloadPlaybackPosition() {
        eventView.reloadPlaybackPosition()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let event = event else { return }

        view.backgroundColor = .fos_systemBackground
        view.addSubview(scrollView)

        scrollView.addSubview(eventView)
        scrollView.contentInset.top = 20
        scrollView.contentInset.bottom = 32
        scrollView.alwaysBounceVertical = true
        scrollView.preservesSuperviewLayoutMargins = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        eventView.event = event
        eventView.delegate = self
        eventView.dataSource = self
        eventView.translatesAutoresizingMaskIntoConstraints = false

        let widthConstraint = eventView.widthAnchor.constraint(equalTo: view.widthAnchor)
        widthConstraint.priority = .defaultLow

        let maxWidthConstraint = eventView.widthAnchor.constraint(lessThanOrEqualToConstant: 500)

        NSLayoutConstraint.activate([widthConstraint, maxWidthConstraint] + [
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            eventView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            eventView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            eventView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            eventView.leadingAnchor.constraint(greaterThanOrEqualTo: scrollView.layoutMarginsGuide.leadingAnchor),
            eventView.trailingAnchor.constraint(lessThanOrEqualTo: scrollView.layoutMarginsGuide.trailingAnchor),
        ])
    }
}

extension EventViewController: EventViewDelegate, EventViewDataSource {
    func eventViewDidTapVideo(_: EventView) {
        delegate?.eventViewControllerDidTapVideo(self)
    }

    func eventView(_: EventView, didSelect attachment: Attachment) {
        delegate?.eventViewController(self, didSelect: attachment)
    }

    func eventView(_: EventView, playbackPositionFor event: Event) -> PlaybackPosition {
        dataSource?.eventViewController(self, playbackPositionFor: event) ?? .beginning
    }
}
