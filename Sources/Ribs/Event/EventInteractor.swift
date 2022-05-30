import AVKit
import RIBs

protocol EventPresentable: Presentable {
  var playbackPosition: PlaybackPosition { get set }
  var showsFavorite: Bool { get set }
  var allowsFavoriting: Bool { get set }
  var showsLivestream: Bool { get set }
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
    presenter.allowsFavoriting = arguments.allowsFavoriting
    presenter.playbackPosition = dependency.playbackService.playbackPosition(forEventWithIdentifier: event.id)

    presenter.showsFavorite = !dependency.favoritesService.canFavorite(event)
    favoritesObserver = dependency.favoritesService.addObserverForEvents { [weak self] _ in
      if let self = self {
        self.presenter.showsFavorite = !self.dependency.favoritesService.canFavorite(self.event)
      }
    }
  }

  override func willResignActive() {
    super.willResignActive()

    if let favoritesObserver = favoritesObserver {
      dependency.favoritesService.removeObserver(favoritesObserver)
    }

    if let finishObserver = finishObserver {
      dependency.notificationCenter.removeObserver(finishObserver)
    }

    if let timeObserver = timeObserver {
      dependency.player.removeTimeObserver(timeObserver)
    }

    do {
      try dependency.audioSession.setActive(false, options: [])
    } catch {
      assertionFailure(error.localizedDescription)
    }
  }
}

extension EventInteractor: EventPresentableListener {
  func toggleFavorite() {
    dependency.favoritesService.toggleFavorite(event)
  }

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
}

private extension EventInteractor {
  var event: Event {
    arguments.event
  }
}
