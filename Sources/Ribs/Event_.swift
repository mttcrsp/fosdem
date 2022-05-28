import AVKit
import RIBs
import SafariServices
import UIKit

typealias EventArguments = Event
typealias EventDependency = HasAudioSession
  & HasFavoritesService
  & HasNotificationCenter
  & HasPlaybackService
  & HasPlayer
  & HasTimeService

protocol EventBuildable {
  func build(with arguments: EventArguments) -> ViewableRouting
}

final class EventBuilder: Builder<EventDependency>, EventBuildable {
  func build(with arguments: EventArguments) -> ViewableRouting {
    let viewController = _EventController()
    let interactor = EventInteractor(arguments: arguments, dependency: dependency, presenter: viewController)
    let router = EventRouter(interactor: interactor, viewController: viewController)
    return router
  }
}

final class EventRouter: ViewableRouter<Interactable, ViewControllable> {}

final class EventInteractor: PresentableInteractor<EventPresentable> {
  private var favoritesObserver: NSObjectProtocol?
  private var finishObserver: NSObjectProtocol?
  private var timeObserver: Any?

  private let arguments: EventArguments
  private let dependency: EventDependency

  init(arguments: EventArguments, dependency: EventDependency, presenter: EventPresentable) {
    self.arguments = arguments
    self.dependency = dependency
    super.init(presenter: presenter)
    presenter.listener = self
  }

  deinit {
    if let timeObserver = timeObserver {
      dependency.player.removeTimeObserver(timeObserver)
    }

    if let finishObserver = finishObserver {
      dependency.notificationCenter.removeObserver(finishObserver)
    }

    if let observer = finishObserver {
      dependency.notificationCenter.removeObserver(observer)
    }

    do {
      try dependency.audioSession.setActive(false, options: [])
    } catch {
      assertionFailure(error.localizedDescription)
    }
  }

  var event: Event {
    arguments
  }

  override func didBecomeActive() {
    super.didBecomeActive()

    presenter.event = event
    presenter.showsFavoriteButton = true // FIXME: handle presentation from years
    presenter.showsLivestream =
      event.links.contains(where: \.isLivestream) &&
      event.isSameDay(as: dependency.timeService.now)
    presenter.playbackPosition =
      dependency.playbackService.playbackPosition(forEventWithIdentifier: event.id)

    favoritesObserver = dependency.favoritesService.addObserverForEvents { [weak self] id in
      if let self = self, self.event.id == id {
        self.presenter.showsFavorite =
          self.dependency.favoritesService.contains(self.event)
      }
    }
  }
}

extension EventInteractor: EventPresentableListener {
  func willBeginFullScreenPlayerPresentation() {
    let event = self.event

    do {
      try dependency.audioSession.setCategory(.playback)
      try dependency.audioSession.setActive(true, options: [])
    } catch {
      assertionFailure(error.localizedDescription)
    }

    let intervalScale = CMTimeScale(NSEC_PER_SEC)
    let interval = CMTime(seconds: 0.1, preferredTimescale: intervalScale)
    timeObserver = dependency.player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
      let position = PlaybackPosition.at(time.seconds)
      self?.dependency.playbackService.setPlaybackPosition(position, forEventWithIdentifier: event.id)
      self?.presenter.playbackPosition = position
    }

    finishObserver = dependency.notificationCenter.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { [weak self] _ in
      let position = PlaybackPosition.end
      self?.dependency.playbackService.setPlaybackPosition(position, forEventWithIdentifier: event.id)
      self?.presenter.playbackPosition = position
    }

    if case let .at(seconds) = dependency.playbackService.playbackPosition(forEventWithIdentifier: event.id) {
      let timeScale = CMTimeScale(NSEC_PER_SEC)
      let time = CMTime(seconds: seconds, preferredTimescale: timeScale)
      dependency.player.seek(to: time)
    }
  }

  func willEndFullScreenPlayerPresentation() {
    if let timeObserver = timeObserver {
      dependency.player.removeTimeObserver(timeObserver)
      self.timeObserver = nil
    }

    if let finishObserver = finishObserver {
      dependency.notificationCenter.removeObserver(finishObserver)
      self.finishObserver = nil
    }
  }

  func didToggleFavorite() {
    if dependency.favoritesService.contains(event) {
      dependency.favoritesService.removeEvent(withIdentifier: event.id)
    } else {
      dependency.favoritesService.addEvent(withIdentifier: event.id)
    }
  }
}

protocol EventPresentable: Presentable {
  var listener: EventPresentableListener? { get set }
  var event: Event? { get set }
  var showsLivestream: Bool { get set }
  var showsFavorite: Bool { get set }
  var showsFavoriteButton: Bool { get set }
  var playbackPosition: PlaybackPosition { get set }
}

protocol EventPresentableListener: AnyObject {
  func didToggleFavorite()
  func willBeginFullScreenPlayerPresentation()
  func willEndFullScreenPlayerPresentation()
}

final class _EventController: EventViewController, EventPresentable, ViewControllable {
  weak var listener: EventPresentableListener?

  private weak var playerViewController: AVPlayerViewController?
  private weak var eventViewController: EventViewController?

  var playbackPosition: PlaybackPosition = .beginning {
    didSet { eventViewController?.reloadPlaybackPosition() }
  }

  var showsFavoriteButton: Bool {
    get { navigationItem.rightBarButtonItem == favoriteButton }
    set { navigationItem.rightBarButtonItem = newValue ? favoriteButton : nil }
  }

  var showsFavorite: Bool {
    get { favoriteButton.accessibilityIdentifier == "unfavorite" }
    set {
      favoriteButton.title = newValue ? L10n.Event.remove : L10n.Event.add
      favoriteButton.accessibilityIdentifier = newValue ? "unfavorite" : "favorite"
    }
  }

  private lazy var favoriteButton: UIBarButtonItem = {
    let favoriteAction = #selector(didToggleFavorite)
    let favoriteButton = UIBarButtonItem(title: nil, style: .plain, target: self, action: favoriteAction)
    return favoriteButton
  }()

  init() {
    super.init(style: {
      if #available(iOS 13.0, *), UIDevice.current.userInterfaceIdiom == .pad {
        return .insetGrouped
      } else {
        return .plain
      }
    }())
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.largeTitleDisplayMode = .never
    dataSource = self
    delegate = self
  }

  @objc private func didToggleFavorite() {
    listener?.didToggleFavorite()
  }
}

extension _EventController: EventViewControllerDelegate, EventViewControllerDataSource {
  func eventViewControllerDidTapLivestream(_ eventViewController: EventViewController) {
    if let event = event, let link = event.links.first(where: \.isLivestream), let url = link.livestreamURL {
      let livestreamViewController = makeVideoViewController(for: url)
      eventViewController.present(livestreamViewController, animated: true)
    }
  }

  func eventViewControllerDidTapVideo(_ eventViewController: EventViewController) {
    if let event = event, let video = event.video, let url = video.url {
      let videoViewController = makeVideoViewController(for: url)
      eventViewController.present(videoViewController, animated: true)
    }
  }

  func eventViewController(_ eventViewController: EventViewController, didSelect attachment: Attachment) {
    let attachmentViewController = makeAttachmentViewController(for: attachment)
    eventViewController.present(attachmentViewController, animated: true)
  }

  func eventViewController(_: EventViewController, playbackPositionFor _: Event) -> PlaybackPosition {
    playbackPosition
  }
}

extension _EventController: AVPlayerViewControllerDelegate {
  func playerViewController(_: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator _: UIViewControllerTransitionCoordinator) {
    listener?.willBeginFullScreenPlayerPresentation()
  }

  func playerViewController(_: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator _: UIViewControllerTransitionCoordinator) {
    listener?.willEndFullScreenPlayerPresentation()
  }
}

private extension _EventController {
  func makeVideoViewController(for url: URL) -> AVPlayerViewController {
    let playerViewController = AVPlayerViewController()
    playerViewController.exitsFullScreenWhenPlaybackEnds = true
    playerViewController.player = AVPlayer(url: url)
    playerViewController.player?.play()
    playerViewController.delegate = self
    self.playerViewController = playerViewController
    return playerViewController
  }

  private func makeAttachmentViewController(for attachment: Attachment) -> UIViewController {
    SFSafariViewController(url: attachment.url)
  }
}
