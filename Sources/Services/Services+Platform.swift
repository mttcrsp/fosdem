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

extension Services: HasAudioSession {
  var audioSession: AVAudioSessionProtocol {
    AVAudioSession.sharedInstance()
  }
}

protocol HasPlayer {
  var player: AVPlayerProtocol { get }
}

extension Services: HasPlayer {
  static let _player = AVPlayer()

  var player: AVPlayerProtocol {
    Services._player
  }
}
