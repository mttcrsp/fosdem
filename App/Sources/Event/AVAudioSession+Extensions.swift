import AVKit

/// @mockable
protocol AVAudioSessionProtocol {
  func setCategory(_ category: AVAudioSession.Category) throws
  func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws
}

extension AVAudioSession: AVAudioSessionProtocol {}
