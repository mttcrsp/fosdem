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
