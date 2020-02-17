import AVKit

final class EventController: UIViewController {
    private weak var eventViewController: EventViewController?

    private lazy var favoriteButton: UIBarButtonItem =
        UIBarButtonItem(title: favoriteTitle, style: .plain, target: self, action: #selector(favoriteTapped))

    private let event: Event
    private let services: Services

    init(event: Event, services: Services) {
        self.event = event
        self.services = services
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        eventViewController?.view.frame = view.bounds
    }

    private var favoritesService: FavoritesService {
        services.favoritesService
    }

    private var isEventFavorite: Bool {
        favoritesService.contains(event)
    }

    private var favoriteTitle: String {
        isEventFavorite
            ? NSLocalizedString("Unfavorite", comment: "")
            : NSLocalizedString("Favorite", comment: "")
    }

    private func makeEventViewController(for event: Event) -> EventViewController {
        let eventViewController = EventViewController()
        eventViewController.hidesBottomBarWhenPushed = true
        eventViewController.delegate = self
        eventViewController.event = event
        self.eventViewController = eventViewController
        return eventViewController
    }

    private func makeVideoViewController(for url: URL) -> AVPlayerViewController {
        let videoViewController = AVPlayerViewController()
        videoViewController.player = AVPlayer(url: url)
        videoViewController.player?.play()
        videoViewController.allowsPictureInPicturePlayback = true

        if #available(iOS 11.0, *) {
            videoViewController.exitsFullScreenWhenPlaybackEnds = true
        }

        return videoViewController
    }

    @objc private func favoriteTapped() {
        if isEventFavorite {
            favoritesService.removeEvent(withIdentifier: event.id)
        } else {
            favoritesService.addEvent(withIdentifier: event.id)
        }
    }
}

extension EventController: EventViewControllerDelegate {
    func eventViewControllerDidTapVideo(_ eventViewController: EventViewController) {
        guard let video = event.video, let url = video.url else { return }
        eventViewController.present(makeVideoViewController(for: url), animated: true)
    }
}
