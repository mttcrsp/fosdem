import AVKit
import Dependencies

final class EventController: UIViewController {
  typealias PlayerViewController = UIViewController & AVPlayerViewControllerProtocol

  @Dependency(\.favoritesClient) var favoritesClient
  @Dependency(\.navigationClient) var navigationClient
  @Dependency(\.playbackClient) var playbackClient
  @Dependency(\.timeClient) var timeClient

  var showsFavoriteButton = true {
    didSet { didChangeShowsFavoriteButton() }
  }

  private weak var playerViewController: PlayerViewController?
  private weak var eventViewController: EventViewController?

  private var favoritesObserver: NSObjectProtocol?
  private var finishObserver: NSObjectProtocol?
  private var timeObserver: Any?

  private let notificationCenter: NotificationCenter
  private let audioSession: AVAudioSessionProtocol

  let event: Event

  init(
    event: Event,
    notificationCenter: NotificationCenter = .default,
    audioSession: AVAudioSessionProtocol = AVAudioSession.sharedInstance()
  ) {
    self.event = event
    self.audioSession = audioSession
    self.notificationCenter = notificationCenter
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    if let observer = favoritesObserver {
      favoritesClient.removeObserver(observer)
    }

    if let observer = timeObserver {
      playerViewController?.player?.removeTimeObserver(observer)
    }

    if let observer = finishObserver {
      notificationCenter.removeObserver(observer)
    }

    do {
      try audioSession.setActive(false, options: [])
    } catch {
      assertionFailure(error.localizedDescription)
    }
  }

  private var isEventFavorite: Bool {
    favoritesClient.contains(event)
  }

  private var favoriteTitle: String {
    isEventFavorite ? L10n.Event.remove : L10n.Event.add
  }

  private var favoriteAccessibilityIdentifier: String {
    isEventFavorite ? "unfavorite" : "favorite"
  }

  private var isEventToday: Bool {
    event.isSameDay(as: timeClient.now())
  }

  private var hasLivestream: Bool {
    event.links.contains(where: \.isLivestream)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.largeTitleDisplayMode = .never

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
      favoritesClient.removeEvent(event.id)
    } else {
      favoritesClient.addEvent(event.id)
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
    favoriteButton.accessibilityIdentifier = favoriteAccessibilityIdentifier
    navigationItem.rightBarButtonItem = favoriteButton

    favoritesObserver = favoritesClient.addObserverForEvents { [weak favoriteButton, weak self] in
      favoriteButton?.accessibilityIdentifier = self?.favoriteAccessibilityIdentifier
      favoriteButton?.title = self?.favoriteTitle
    }
  }

  private func hideFavoriteButton() {
    if let observer = favoritesObserver {
      favoritesClient.removeObserver(observer)
      favoritesObserver = nil
    }

    navigationItem.rightBarButtonItem = nil
  }
}

extension EventController: EventViewControllerDelegate, EventViewControllerDataSource {
  func eventViewControllerDidTapLivestream(_ eventViewController: EventViewController) {
    if let link = event.links.first(where: \.isLivestream), let url = link.livestreamURL {
      let livestreamViewController = makeVideoViewController(for: url)
      eventViewController.present(livestreamViewController, animated: true)
    }
  }

  func eventViewControllerDidTapVideo(_ eventViewController: EventViewController) {
    if let video = event.video, let url = video.url {
      let videoViewController = makeVideoViewController(for: url)
      eventViewController.present(videoViewController, animated: true)
    }
  }

  func eventViewController(_ eventViewController: EventViewController, didSelect url: URL) {
    let attachmentViewController = makeSafariViewController(for: url)
    eventViewController.present(attachmentViewController, animated: true)
  }

  func eventViewController(_: EventViewController, playbackPositionFor event: Event) -> PlaybackPosition {
    playbackClient.playbackPosition(event.id)
  }
}

extension EventController: AVPlayerViewControllerDelegate {
  func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator _: UIViewControllerTransitionCoordinator) {
    let event = self.event

    do {
      try audioSession.setCategory(.playback)
      try audioSession.setActive(true, options: [])
    } catch {
      assertionFailure(error.localizedDescription)
    }

    let intervalScale = CMTimeScale(NSEC_PER_SEC)
    let interval = CMTime(seconds: 0.1, preferredTimescale: intervalScale)
    timeObserver = playerViewController.player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
      self?.playbackClient.setPlaybackPosition(.at(time.seconds), event.id)
      self?.eventViewController?.reloadPlaybackPosition()
    }

    finishObserver = notificationCenter.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { [weak self] _ in
      self?.playbackClient.setPlaybackPosition(.end, event.id)
      self?.eventViewController?.reloadPlaybackPosition()
    }

    if case let .at(seconds) = playbackClient.playbackPosition(event.id) {
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
    let eventViewController = EventViewController(style: .insetGrouped)
    eventViewController.showsLivestream = hasLivestream && isEventToday
    eventViewController.dataSource = self
    eventViewController.delegate = self
    eventViewController.event = event
    self.eventViewController = eventViewController
    return eventViewController
  }

  func makeVideoViewController(for url: URL) -> PlayerViewController {
    let playerViewController = navigationClient.makePlayerViewController()
    playerViewController.exitsFullScreenWhenPlaybackEnds = true
    playerViewController.player = AVPlayer(url: url)
    playerViewController.player?.play()
    playerViewController.delegate = self
    self.playerViewController = playerViewController
    return playerViewController
  }

  private func makeSafariViewController(for url: URL) -> UIViewController {
    navigationClient.makeSafariViewController(url)
  }
}
