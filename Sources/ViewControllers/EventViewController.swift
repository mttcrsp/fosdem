import UIKit

protocol EventViewControllerDelegate: AnyObject {
    func eventViewControllerDidTapVideo(_ eventViewController: EventViewController)
    func eventViewController(_ eventViewController: EventViewController, didSelect attachment: Attachment)
}

final class EventViewController: UIViewController {
    weak var delegate: EventViewControllerDelegate?

    var event: Event?

    private lazy var eventView = EventView()
    private lazy var scrollView = UIScrollView()

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let event = event else { return }

        view.backgroundColor = .fos_systemBackground
        view.addSubview(scrollView)

        scrollView.addSubview(eventView)
        scrollView.contentInset.top = 16
        scrollView.contentInset.bottom = 16
        scrollView.alwaysBounceVertical = true
        scrollView.preservesSuperviewLayoutMargins = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        eventView.event = event
        eventView.delegate = self
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

extension EventViewController: EventViewDelegate {
    func eventViewDidTapVideo(_: EventView) {
        delegate?.eventViewControllerDidTapVideo(self)
    }

    func eventView(_: EventView, didSelect attachment: Attachment) {
        delegate?.eventViewController(self, didSelect: attachment)
    }
}
