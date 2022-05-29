import AVFoundation

protocol HasNotificationCenter {
  var notificationCenter: NotificationCenter { get }
}

extension Services: HasNotificationCenter {
  var notificationCenter: NotificationCenter {
    .default
  }
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

extension Services: HasAudioSession {
  var audioSession: AVAudioSessionProtocol {
    AVAudioSession.sharedInstance()
  }
}

extension AVPlayer: AVPlayerProtocol {}

extension Services: HasPlayer {
  static let _player = AVPlayer()

  var player: AVPlayerProtocol {
    Services._player
  }
}
