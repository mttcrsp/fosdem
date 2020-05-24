import AVKit
import SafariServices

final class EventController: UIViewController {
    var showsFavoriteButton = true {
        didSet { didChangeShowsFavoriteButton() }
    }

    private weak var videoViewController: AVPlayerViewController?
    private weak var eventViewController: EventViewController?

    private var favoritesObserver: NSObjectProtocol?
    private var finishObserver: NSObjectProtocol?
    private var timeObserver: Any?

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

        if let observer = timeObserver {
            videoViewController?.player?.removeTimeObserver(observer)
        }

        if let observer = finishObserver {
            notificationCenter.removeObserver(observer)
        }

        do {
            try session.setActive(false)
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    private var favoritesService: FavoritesService {
        services.favoritesService
    }

    private var playbackService: PlaybackService {
        services.playbackService
    }

    private var notificationCenter: NotificationCenter {
        .default
    }

    private var session: AVAudioSession {
        .sharedInstance()
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

extension EventController: EventViewControllerDelegate, EventViewControllerDataSource {
    func eventViewControllerDidTapVideo(_ eventViewController: EventViewController) {
        guard let video = event.video, let url = video.url else { return }

        let videoViewController = makeVideoViewController(for: url)
        eventViewController.present(videoViewController, animated: true)
    }

    func eventViewController(_ eventViewController: EventViewController, didSelect attachment: Attachment) {
        let attachmentViewController = makeAttachmentViewController(for: attachment)
        eventViewController.present(attachmentViewController, animated: true)
    }

    func eventViewController(_: EventViewController, playbackPositionFor event: Event) -> PlaybackPosition {
        playbackService.playbackPosition(forEventWithIdentifier: event.id)
    }
}

extension EventController: AVPlayerViewControllerDelegate {
    func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator _: UIViewControllerTransitionCoordinator) {
        let event = self.event

        do {
            try session.setCategory(.playback)
            try session.setActive(true)
        } catch {
            assertionFailure(error.localizedDescription)
        }

        let intervalScale = CMTimeScale(NSEC_PER_SEC)
        let interval = CMTime(seconds: 0.1, preferredTimescale: intervalScale)
        timeObserver = playerViewController.player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.playbackService.setPlaybackPosition(.at(time.seconds), forEventWithIdentifier: event.id)
            self?.eventViewController?.reloadPlaybackPosition()
        }

        finishObserver = notificationCenter.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { [weak self] _ in
            self?.playbackService.setPlaybackPosition(.end, forEventWithIdentifier: event.id)
            self?.eventViewController?.reloadPlaybackPosition()
        }

        if case let .at(seconds) = playbackService.playbackPosition(forEventWithIdentifier: event.id) {
            let timeScale = CMTimeScale(NSEC_PER_SEC)
            let time = CMTime(seconds: seconds, preferredTimescale: timeScale)
            playerViewController.player?.seek(to: time)
        }
    }

    func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator _: UIViewControllerTransitionCoordinator) {
        if let observer = timeObserver {
            playerViewController.player?.removeTimeObserver(observer)
            timeObserver = nil
        }

        if let observer = finishObserver {
            notificationCenter.removeObserver(observer)
            finishObserver = nil
        }
    }
}

private extension EventController {
    func makeEventViewController(for event: Event) -> EventViewController {
        let eventViewController = EventViewController()
        eventViewController.dataSource = self
        eventViewController.delegate = self
        eventViewController.event = event
        self.eventViewController = eventViewController
        return eventViewController
    }

    func makeVideoViewController(for url: URL) -> AVPlayerViewController {
        let videoViewController = AVPlayerViewController()
        videoViewController.allowsPictureInPicturePlayback = true
        videoViewController.player = AVPlayer(url: url)
        videoViewController.player?.play()
        videoViewController.delegate = self
        self.videoViewController = videoViewController

        if #available(iOS 11.0, *) {
            videoViewController.exitsFullScreenWhenPlaybackEnds = true
        }

        return videoViewController
    }

    private func makeAttachmentViewController(for attachment: Attachment) -> SFSafariViewController {
        SFSafariViewController(url: attachment.url)
    }
}
