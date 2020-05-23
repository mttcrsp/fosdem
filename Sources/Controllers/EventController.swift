import AVKit
import SafariServices

final class EventController: UIViewController {
    var showsFavoriteButton = true {
        didSet { didChangeShowsFavoriteButton() }
    }

    private weak var eventViewController: EventViewController?

    private var favoritesObserver: NSObjectProtocol?

    private let services: Services

    let event: Event

    init(event: Event, services: Services) {
        self.event = event
        self.services = services
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let observer = favoritesObserver {
            favoritesService.removeObserver(observer)
        }
    }

    private var favoritesService: FavoritesService {
        services.favoritesService
    }

    private var isEventFavorite: Bool {
        favoritesService.contains(event)
    }

    private var favoriteTitle: String {
        isEventFavorite
            ? NSLocalizedString("unfavorite", comment: "")
            : NSLocalizedString("favorite", comment: "")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }

        let eventViewController = makeEventViewController(for: event)
        addChild(eventViewController)
        view.addSubview(eventViewController.view)
        eventViewController.didMove(toParent: self)

        didChangeShowsFavoriteButton()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        eventViewController?.view.frame = view.bounds
    }

    @objc private func didToggleFavorite() {
        if isEventFavorite {
            favoritesService.removeEvent(withIdentifier: event.id)
        } else {
            favoritesService.addEvent(withIdentifier: event.id)
        }
    }

    private func didChangeShowsFavoriteButton() {
        guard isViewLoaded else { return }

        if showsFavoriteButton {
            showFavoriteButton()
        } else {
            hideFavoriteButton()
        }
    }

    private func showFavoriteButton() {
        let favoriteAction = #selector(didToggleFavorite)
        let favoriteButton = UIBarButtonItem(title: favoriteTitle, style: .plain, target: self, action: favoriteAction)
        navigationItem.rightBarButtonItem = favoriteButton

        favoritesObserver = favoritesService.addObserverForEvents { [weak favoriteButton, weak self] in
            favoriteButton?.title = self?.favoriteTitle
        }
    }

    private func hideFavoriteButton() {
        if let observer = favoritesObserver {
            favoritesService.removeObserver(observer)
            favoritesObserver = nil
        }

        navigationItem.rightBarButtonItem = nil
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
        SFSafariViewController(url: attachment.url)
    }
}
