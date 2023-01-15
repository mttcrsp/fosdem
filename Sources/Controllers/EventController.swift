import AVKit

final class EventController: UIViewController {
  typealias Dependencies = HasFavoritesService & HasPlaybackService & HasTimeService & HasNavigationService
  typealias PlayerViewController = UIViewController & AVPlayerViewControllerProtocol

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
  private let dependencies: Dependencies

  let event: Event

  init(
    event: Event,
    dependencies: Dependencies,
    notificationCenter: NotificationCenter = .default,
    audioSession: AVAudioSessionProtocol = AVAudioSession.sharedInstance()
  ) {
    self.event = event
    self.dependencies = dependencies
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
      dependencies.favoritesService.removeObserver(observer)
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
    dependencies.favoritesService.contains(event)
  }

  private var favoriteTitle: String {
    isEventFavorite ? L10n.Event.remove : L10n.Event.add
  }

  private var favoriteAccessibilityIdentifier: String {
    isEventFavorite ? "unfavorite" : "favorite"
  }

  private var isEventToday: Bool {
    event.isSameDay(as: dependencies.timeService.now)
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
      dependencies.favoritesService.removeEvent(withIdentifier: event.id)
    } else {
      dependencies.favoritesService.addEvent(withIdentifier: event.id)
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

    favoritesObserver = dependencies.favoritesService.addObserverForEvents { [weak favoriteButton, weak self] _ in
      favoriteButton?.accessibilityIdentifier = self?.favoriteAccessibilityIdentifier
      favoriteButton?.title = self?.favoriteTitle
    }
  }

  private func hideFavoriteButton() {
    if let observer = favoritesObserver {
      dependencies.favoritesService.removeObserver(observer)
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
    dependencies.playbackService.playbackPosition(forEventWithIdentifier: event.id)
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
      self?.dependencies.playbackService.setPlaybackPosition(.at(time.seconds), forEventWithIdentifier: event.id)
      self?.eventViewController?.reloadPlaybackPosition()
    }

    finishObserver = notificationCenter.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { [weak self] _ in
      self?.dependencies.playbackService.setPlaybackPosition(.end, forEventWithIdentifier: event.id)
      self?.eventViewController?.reloadPlaybackPosition()
    }

    if case let .at(seconds) = dependencies.playbackService.playbackPosition(forEventWithIdentifier: event.id) {
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
    var style: UITableView.Style = .plain
    if #available(iOS 13.0, *), traitCollection.userInterfaceIdiom == .pad {
      style = .insetGrouped
    }

    let eventViewController = EventViewController(style: style)
    eventViewController.showsLivestream = hasLivestream && isEventToday
    eventViewController.dataSource = self
    eventViewController.delegate = self
    eventViewController.event = event
    self.eventViewController = eventViewController
    return eventViewController
  }

  func makeVideoViewController(for url: URL) -> PlayerViewController {
    let playerViewController = dependencies.navigationService.makePlayerViewController()
    playerViewController.exitsFullScreenWhenPlaybackEnds = true
    playerViewController.player = AVPlayer(url: url)
    playerViewController.player?.play()
    playerViewController.delegate = self
    self.playerViewController = playerViewController
    return playerViewController
  }

  private func makeSafariViewController(for url: URL) -> UIViewController {
    dependencies.navigationService.makeSafariViewController(with: url)
  }
}
