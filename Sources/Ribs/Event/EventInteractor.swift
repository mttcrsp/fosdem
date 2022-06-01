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
  private let services: EventServices

  init(arguments: EventArguments, presenter: EventPresentable, services: EventServices) {
    self.arguments = arguments
    self.services = services
    super.init(presenter: presenter)
  }

  override func didBecomeActive() {
    super.didBecomeActive()

    let hasLivestream = event.links.contains(where: \.isLivestream)
    let isLivestreamToday = event.isSameDay(as: services.timeService.now)
    presenter.showsLivestream = hasLivestream && isLivestreamToday
    presenter.allowsFavoriting = arguments.allowsFavoriting
    presenter.playbackPosition = services.playbackService.playbackPosition(forEventWithIdentifier: event.id)

    presenter.showsFavorite = !services.favoritesService.canFavorite(event)
    favoritesObserver = services.favoritesService.addObserverForEvents { [weak self] _ in
      if let self = self {
        self.presenter.showsFavorite = !self.services.favoritesService.canFavorite(self.event)
      }
    }
  }

  override func willResignActive() {
    super.willResignActive()

    if let favoritesObserver = favoritesObserver {
      services.favoritesService.removeObserver(favoritesObserver)
    }

    if let finishObserver = finishObserver {
      services.notificationCenter.removeObserver(finishObserver)
    }

    if let timeObserver = timeObserver {
      services.player.removeTimeObserver(timeObserver)
    }

    do {
      try services.audioSession.setActive(false, options: [])
    } catch {
      assertionFailure(error.localizedDescription)
    }
  }
}

extension EventInteractor: EventPresentableListener {
  func toggleFavorite() {
    services.favoritesService.toggleFavorite(event)
  }

  func beginFullScreenPlayerPresentation() {
    let eventID = event.id

    do {
      try services.audioSession.setCategory(.playback)
      try services.audioSession.setActive(true, options: [])
    } catch {
      assertionFailure(error.localizedDescription)
    }

    let intervalScale = CMTimeScale(NSEC_PER_SEC)
    let interval = CMTime(seconds: 0.1, preferredTimescale: intervalScale)
    timeObserver = services.player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
      let position = PlaybackPosition.at(time.seconds)
      self?.services.playbackService.setPlaybackPosition(position, forEventWithIdentifier: eventID)
      self?.presenter.playbackPosition = position
    }

    finishObserver = services.notificationCenter.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { [weak self] _ in
      let position = PlaybackPosition.end
      self?.services.playbackService.setPlaybackPosition(position, forEventWithIdentifier: eventID)
      self?.presenter.playbackPosition = position
    }

    if case let .at(seconds) = services.playbackService.playbackPosition(forEventWithIdentifier: eventID) {
      let timeScale = CMTimeScale(NSEC_PER_SEC)
      let time = CMTime(seconds: seconds, preferredTimescale: timeScale)
      services.player.seek(to: time)
    }
  }

  func endFullScreenPlayerPresentation() {
    if let timeObserver = timeObserver {
      services.player.removeTimeObserver(timeObserver)
      self.timeObserver = nil
    }

    if let finishObserver = finishObserver {
      services.notificationCenter.removeObserver(finishObserver)
      self.finishObserver = nil
    }
  }
}

private extension EventInteractor {
  var event: Event {
    arguments.event
  }
}
