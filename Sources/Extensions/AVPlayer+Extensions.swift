import AVKit

/// @mockable
protocol AVPlayerProtocol {
  func seek(to time: CMTime)
  func addPeriodicTimeObserver(forInterval interval: CMTime, queue: DispatchQueue?, using block: @escaping (CMTime) -> Void) -> Any
  func removeTimeObserver(_ observer: Any)
}

extension AVPlayer: AVPlayerProtocol {}
