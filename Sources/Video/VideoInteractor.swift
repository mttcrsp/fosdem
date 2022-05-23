import AVFoundation

protocol HasNotificationCenter {
  var notificationCenter: NotificationCenter { get }
}

protocol HasAudioSession {
  var audioSession: AVAudioSessionProtocol { get }
}

protocol HasPlayer {
  var player: AVPlayerProtocol { get }
}

protocol AVPlayerProtocol {
  func seek(to time: CMTime)
  func addPeriodicTimeObserver(forInterval interval: CMTime, queue: DispatchQueue?, using block: @escaping (CMTime) -> Void) -> Any
  func removeTimeObserver(_ observer: Any)
}

extension AVPlayer: AVPlayerProtocol {}

protocol VideoPresentable {}

class VideoInteractor {
  typealias Arguments = (url: URL, event: Event)
  typealias Dependencies = HasPlaybackService & HasTimeService & HasNotificationCenter & HasAudioSession & HasPlayer

  private var finishObserver: NSObjectProtocol?
  private var timeObserver: Any?

  private let arguments: Arguments
  private let dependencies: Dependencies

  init(arguments: Arguments, dependencies: Dependencies) {
    self.arguments = arguments
    self.dependencies = dependencies
  }

  deinit {
    if let timeObserver = timeObserver {
      dependencies.player.removeTimeObserver(timeObserver)
    }

    if let finishObserver = finishObserver {
      dependencies.notificationCenter.removeObserver(finishObserver)
    }

    do {
      try dependencies.audioSession.setActive(false, options: [])
    } catch {
      assertionFailure(error.localizedDescription)
    }
  }
}

extension VideoInteractor: VideoViewControllerListener {
  func willBeginFullScreenPresentation() {
    do {
      try dependencies.audioSession.setCategory(.playback)
      try dependencies.audioSession.setActive(true, options: [])
    } catch {
      assertionFailure(error.localizedDescription)
    }

    let intervalScale = CMTimeScale(NSEC_PER_SEC)
    let interval = CMTime(seconds: 0.1, preferredTimescale: intervalScale)
    timeObserver = dependencies.player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
      _ = self
      _ = time
    }

    finishObserver = dependencies.notificationCenter.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { [weak self] _ in
      if let self = self {
        self.dependencies.playbackService.setPlaybackPosition(.end, forEventWithIdentifier: self.arguments.event.id)
        //
      }
    }

    if case let .at(seconds) = dependencies.playbackService.playbackPosition(forEventWithIdentifier: arguments.event.id) {
      let timeScale = CMTimeScale(NSEC_PER_SEC)
      let time = CMTime(seconds: seconds, preferredTimescale: timeScale)
      _ = time
    }
  }

  func willEndFullScreenPresentation() {
    if let observer = timeObserver {
      dependencies.player.removeTimeObserver(observer)
      timeObserver = nil
    }

    if let observer = finishObserver {
      dependencies.notificationCenter.removeObserver(observer)
      finishObserver = nil
    }
  }
}
