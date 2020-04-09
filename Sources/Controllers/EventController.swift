import AVKit
import SafariServices

final class EventController: UIViewController {
    private weak var eventViewController: EventViewController?

    private var observation: NSObjectProtocol?

    private let event: Event
    private let favoritesService: FavoritesService?

    init(event: Event, favoritesService: FavoritesService? = nil) {
        self.event = event
        self.favoritesService = favoritesService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var isEventFavorite: Bool {
        favoritesService?.contains(event) ?? false
    }

    private var favoriteTitle: String {
        isEventFavorite
            ? NSLocalizedString("unfavorite", comment: "")
            : NSLocalizedString("favorite", comment: "")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let eventViewController = makeEventViewController(for: event)
        addChild(eventViewController)
        view.addSubview(eventViewController.view)
        eventViewController.didMove(toParent: self)

        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }

        guard let favoritesService = favoritesService else { return }

        let favoriteAction = #selector(didToggleFavorite)
        let favoriteButton = UIBarButtonItem(title: favoriteTitle, style: .plain, target: self, action: favoriteAction)
        navigationItem.rightBarButtonItem = favoriteButton

        observation = favoritesService.addObserverForEvents { [weak favoriteButton, weak self] in
            favoriteButton?.title = self?.favoriteTitle
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        eventViewController?.view.frame = view.bounds
    }

    @objc private func didToggleFavorite() {
        if isEventFavorite {
            favoritesService?.removeEvent(withIdentifier: event.id)
        } else {
            favoritesService?.addEvent(withIdentifier: event.id)
        }
    }
}

extension EventController: EventViewControllerDelegate {
    func eventViewControllerDidTapVideo(_ eventViewController: EventViewController) {
        guard let video = event.video, let url = video.url else { return }

        let videoViewController = makeVideoViewController(for: url)
        eventViewController.present(videoViewController, animated: true)
    }

    func eventViewController(_ eventViewController: EventViewController, didSelect attachment: Attachment) {
        let attachmentViewController = makeAttachmentViewController(for: attachment)
        eventViewController.present(attachmentViewController, animated: true)
    }
}

private extension EventController {
    func makeEventViewController(for event: Event) -> EventViewController {
        let eventViewController = EventViewController()
        eventViewController.delegate = self
        eventViewController.event = event
        self.eventViewController = eventViewController
        return eventViewController
    }

    func makeVideoViewController(for url: URL) -> AVPlayerViewController {
        let videoViewController = AVPlayerViewController()
        videoViewController.player = AVPlayer(url: url)
        videoViewController.player?.play()
        videoViewController.allowsPictureInPicturePlayback = true

        if #available(iOS 11.0, *) {
            videoViewController.exitsFullScreenWhenPlaybackEnds = true
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback)
            try session.setActive(true)

            let center = NotificationCenter.default
            center.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { _ in
                do {
                    try session.setActive(false)
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }
        } catch {
            assertionFailure(error.localizedDescription)
        }

        return videoViewController
    }

    private func makeAttachmentViewController(for attachment: Attachment) -> SFSafariViewController {
        .init(url: attachment.url)
    }
}
