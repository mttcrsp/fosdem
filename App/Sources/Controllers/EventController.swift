import AVKit

final class EventController: UIViewController {
  typealias Dependencies = HasFavoritesService & HasNavigationService & HasPersistenceService & HasPlaybackService & HasTimeService & HasTimeFormattingService
  typealias PlayerViewController = AVPlayerViewControllerProtocol & UIViewController

  var showsFavoriteButton = true {
    didSet { didChangeShowsFavoriteButton() }
  }

  var allowsTrackSelection = true {
    didSet { didChangeAllowsTrackSelection() }
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
    Calendar.gregorian.isDate(event.date, inSameDayAs: dependencies.timeService.now)
  }

  private var hasLivestream: Bool {
    event.links.contains(where: \.isLivestream)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.backButtonTitle = event.title
    navigationItem.largeTitleDisplayMode = .never

    let style = traitCollection.userInterfaceIdiom == .pad ? UITableView.Style.insetGrouped : .plain
    let eventViewController = EventViewController(style: style)
    eventViewController.allowsTrackSelection = allowsTrackSelection
    eventViewController.showsLivestream = hasLivestream && isEventToday
    eventViewController.dependencies = dependencies
    eventViewController.dataSource = self
    eventViewController.delegate = self
    eventViewController.event = event
    self.eventViewController = eventViewController

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

  private func didChangeAllowsTrackSelection() {
    eventViewController?.allowsTrackSelection = allowsTrackSelection
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

    favoritesObserver = dependencies.favoritesService.addObserverForEvents { [weak favoriteButton, weak self] in
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
  func eventViewController(_: EventViewController, playbackPositionFor event: Event) -> PlaybackPosition {
    dependencies.playbackService.playbackPosition(forEventWithIdentifier: event.id)
  }

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
    let attachmentViewController = dependencies.navigationService.makeSafariViewController(with: url)
    eventViewController.present(attachmentViewController, animated: true)
  }

  func eventViewControllerDidTapTrack(_ eventViewController: EventViewController) {
    let operation = GetTrackByName(name: event.track)
    dependencies.persistenceService.performRead(operation) { result in
      DispatchQueue.main.async { [weak self] in
        switch result {
        case let .success(track?):
          self?.eventViewController(eventViewController, didLoad: track)
        case .success, .failure:
          self?.eventViewControllerDidFailPresentation(eventViewController)
        }
      }
    }
  }

  private func eventViewController(_ eventViewController: EventViewController, didLoad track: Track) {
    let style = traitCollection.userInterfaceIdiom == .pad ? UITableView.Style.insetGrouped : .grouped
    let trackViewController = dependencies.navigationService.makeTrackViewController(for: track, style: style)
    trackViewController.title = track.formattedName
    trackViewController.load { [weak self] error in
      if error != nil {
        self?.eventViewControllerDidFailPresentation(eventViewController)
      } else {
        eventViewController.show(trackViewController, sender: nil)
      }
    }
  }

  private func eventViewControllerDidFailPresentation(_ eventViewController: EventViewController) {
    let errorViewController = UIAlertController.makeErrorController()
    eventViewController.show(errorViewController, sender: nil)
  }

  private func makeVideoViewController(for url: URL) -> PlayerViewController {
    let playerViewController = dependencies.navigationService.makePlayerViewController()
    playerViewController.exitsFullScreenWhenPlaybackEnds = true
    playerViewController.player = AVPlayer(url: url)
    playerViewController.player?.play()
    playerViewController.delegate = self
    self.playerViewController = playerViewController
    return playerViewController
  }
}

extension EventController: AVPlayerViewControllerDelegate {
  func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator _: UIViewControllerTransitionCoordinator) {
    let event = event

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
