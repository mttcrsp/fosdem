import AVFoundation
import Combine

struct EventOptions: OptionSet {
  let rawValue: Int
  static let enableFavoriting = EventOptions(rawValue: 1 << 0)
  static let enableTrackSelection = EventOptions(rawValue: 1 << 0)
}

final class EventViewModel {
  typealias Dependencies = HasFavoritesService & HasPersistenceService & HasPlaybackService & HasTimeService

  let event: Event
  let options: EventOptions
  let didLoadVideoURL = PassthroughSubject<URL, Never>()
  let didLoadTrack = PassthroughSubject<Result<Track?, Error>, Never>()
  let didUpdatePlaybackPosition = PassthroughSubject<Void, Never>()
  @Published var isEventFavorite = false
  private var favoritesObserver: NSObjectProtocol?
  private var finishObserver: NSObjectProtocol?
  private var playbackObserver: NSObjectProtocol?
  private var timeObserver: Any?
  private let notificationCenter: NotificationCenter
  private let audioSession: AVAudioSessionProtocol
  private let dependencies: Dependencies

  init(event: Event, options: EventOptions, dependencies: Dependencies, notificationCenter: NotificationCenter = .default, audioSession: AVAudioSessionProtocol = AVAudioSession.sharedInstance()) {
    self.event = event
    self.options = options
    self.dependencies = dependencies
    self.audioSession = audioSession
    self.notificationCenter = notificationCenter
  }

  var playbackPosition: PlaybackPosition {
    dependencies.playbackService.playbackPosition(forEventWithIdentifier: event.id)
  }

  var showsLivestream: Bool {
    event.links.contains(where: \.isLivestream) &&
      event.isSameDay(as: dependencies.timeService.now)
  }

  func didLoad() {
    playbackObserver = dependencies.playbackService.addObserver { [weak self] in
      self?.didUpdatePlaybackPosition.send()
    }

    if options.contains(.enableFavoriting) {
      isEventFavorite = dependencies.favoritesService.contains(event)
      favoritesObserver = dependencies.favoritesService.addObserverForEvents { [weak self] in
        guard let self else { return }
        isEventFavorite = dependencies.favoritesService.contains(event)
      }
    }
  }

  func didUnload() {
    do {
      try audioSession.setActive(false, options: [])
    } catch {
      assertionFailure(error.localizedDescription)
    }

    if let observer = favoritesObserver {
      dependencies.favoritesService.removeObserver(observer)
    }

    if let observer = playbackObserver {
      dependencies.playbackService.removeObserver(observer)
    }
  }

  func didToggleFavorite() {
    if isEventFavorite {
      dependencies.favoritesService.removeEvent(withIdentifier: event.id)
    } else {
      dependencies.favoritesService.addEvent(withIdentifier: event.id)
    }
  }

  func didSelectTrack() {
    let operation = GetTrackByName(name: event.track)
    dependencies.persistenceService.performRead(operation) { [weak self] result in
      self?.didLoadTrack.send(result)
    }
  }

  func didSelectLivestream() {
    if let link = event.links.first(where: \.isLivestream), let url = link.livestreamURL {
      didLoadVideoURL.send(url)
    }
  }

  func didSelectVideo() {
    if let video = event.video, let url = video.url {
      didLoadVideoURL.send(url)
    }
  }

  func willBeginVideoPlayback(with player: AVPlayer) {
    do {
      try audioSession.setCategory(.playback)
      try audioSession.setActive(true, options: [])
    } catch {
      assertionFailure(error.localizedDescription)
    }

    if case let .at(seconds) = dependencies.playbackService.playbackPosition(forEventWithIdentifier: event.id) {
      player.seek(to: CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
    }

    let intervalScale = CMTimeScale(NSEC_PER_SEC)
    let interval = CMTime(seconds: 0.1, preferredTimescale: intervalScale)
    timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
      guard let self else { return }
      dependencies.playbackService.setPlaybackPosition(.at(time.seconds), forEventWithIdentifier: event.id)
    }

    finishObserver = notificationCenter.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { [weak self] _ in
      guard let self else { return }
      dependencies.playbackService.setPlaybackPosition(.end, forEventWithIdentifier: event.id)
    }
  }

  func didEndVideoPlayback(with player: AVPlayer) {
    if let observer = timeObserver {
      player.removeTimeObserver(observer)
      timeObserver = nil
    }

    if let observer = finishObserver {
      notificationCenter.removeObserver(observer)
      finishObserver = nil
    }
  }
}
