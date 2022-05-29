import AVKit
import RIBs
import SafariServices
import UIKit

struct EventArguments {
  let event: Event
  let allowsFavoriting: Bool

  init(event: Event, allowsFavoriting: Bool = true) {
    self.event = event
    self.allowsFavoriting = allowsFavoriting
  }
}

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
    let viewController = EventContainerViewController(event: arguments.event)
    let interactor = EventInteractor(arguments: arguments, dependency: dependency, presenter: viewController)
    let router = ViewableRouter(interactor: interactor, viewController: viewController)
    viewController.listener = interactor
    return router
  }
}

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
  }

  override func didBecomeActive() {
    super.didBecomeActive()

    let hasLivestream = event.links.contains(where: \.isLivestream)
    let isLivestreamToday = event.isSameDay(as: dependency.timeService.now)
    presenter.showsLivestream = hasLivestream && isLivestreamToday
    presenter.showsFavoriteButton = arguments.allowsFavoriting
    presenter.playbackPosition = dependency.playbackService.playbackPosition(forEventWithIdentifier: event.id)

    favoritesObserver = dependency.favoritesService.addObserverForEvents { [weak self] _ in
      if let self = self {
        self.presenter.showsFavorite = self.dependency.favoritesService.contains(self.event)
      }
    }
  }

  override func willResignActive() {
    super.willResignActive()

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
}

extension EventInteractor: EventPresentableListener {
  func beginFullScreenPlayerPresentation() {
    let eventID = event.id

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
      self?.dependency.playbackService.setPlaybackPosition(position, forEventWithIdentifier: eventID)
      self?.presenter.playbackPosition = position
    }

    finishObserver = dependency.notificationCenter.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { [weak self] _ in
      let position = PlaybackPosition.end
      self?.dependency.playbackService.setPlaybackPosition(position, forEventWithIdentifier: eventID)
      self?.presenter.playbackPosition = position
    }

    if case let .at(seconds) = dependency.playbackService.playbackPosition(forEventWithIdentifier: eventID) {
      let timeScale = CMTimeScale(NSEC_PER_SEC)
      let time = CMTime(seconds: seconds, preferredTimescale: timeScale)
      dependency.player.seek(to: time)
    }
  }

  func endFullScreenPlayerPresentation() {
    if let timeObserver = timeObserver {
      dependency.player.removeTimeObserver(timeObserver)
      self.timeObserver = nil
    }

    if let finishObserver = finishObserver {
      dependency.notificationCenter.removeObserver(finishObserver)
      self.finishObserver = nil
    }
  }

  func toggleFavorite() {
    if dependency.favoritesService.contains(event) {
      dependency.favoritesService.removeEvent(withIdentifier: event.id)
    } else {
      dependency.favoritesService.addEvent(withIdentifier: event.id)
    }
  }
}

private extension EventInteractor {
  var event: Event {
    arguments.event
  }
}

protocol EventPresentable: Presentable {
  var playbackPosition: PlaybackPosition { get set }
  var showsFavorite: Bool { get set }
  var showsFavoriteButton: Bool { get set }
  var showsLivestream: Bool { get set }
}

protocol EventPresentableListener: AnyObject {
  func toggleFavorite()
  func beginFullScreenPlayerPresentation()
  func endFullScreenPlayerPresentation()
}

final class EventContainerViewController: EventViewController, EventPresentable, ViewControllable {
  weak var listener: EventPresentableListener?

  private weak var playerViewController: AVPlayerViewController?
  private weak var eventViewController: EventViewController?

  var showsFavoriteButton: Bool {
    get { navigationItem.rightBarButtonItem == favoriteButton }
    set { navigationItem.rightBarButtonItem = newValue ? favoriteButton : nil }
  }

  var showsFavorite: Bool {
    get {
      favoriteButton.accessibilityIdentifier == "unfavorite"
    }
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

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.largeTitleDisplayMode = .never
    eventListener = self
  }
}

extension EventContainerViewController: EventViewControllerListener {
  func eventViewController(_ eventViewController: EventViewController, didSelect attachment: Attachment) {
    let attachmentViewController = SFSafariViewController(url: attachment.url)
    eventViewController.present(attachmentViewController, animated: true)
  }

  func eventViewControllerDidTapLivestream(_: EventViewController) {
    if let link = event.links.first(where: \.isLivestream), let url = link.livestreamURL {
      showPlayerViewController(with: url)
    }
  }

  func eventViewControllerDidTapVideo(_: EventViewController) {
    if let video = event.video, let url = video.url {
      showPlayerViewController(with: url)
    }
  }

  private func showPlayerViewController(with url: URL) {
    let playerViewController = AVPlayerViewController()
    playerViewController.exitsFullScreenWhenPlaybackEnds = true
    playerViewController.player = AVPlayer(url: url)
    playerViewController.player?.play()
    playerViewController.delegate = self
    self.playerViewController = playerViewController
    present(playerViewController, animated: true)
  }
}

extension EventContainerViewController: AVPlayerViewControllerDelegate {
  func playerViewController(_: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator _: UIViewControllerTransitionCoordinator) {
    listener?.beginFullScreenPlayerPresentation()
  }

  func playerViewController(_: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator _: UIViewControllerTransitionCoordinator) {
    listener?.endFullScreenPlayerPresentation()
  }
}

private extension EventContainerViewController {
  @objc func didToggleFavorite() {
    listener?.toggleFavorite()
  }
}
