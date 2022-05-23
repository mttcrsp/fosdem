import AVKit

protocol VideoViewControllerListener: AnyObject {
  func willBeginFullScreenPresentation()
  func willEndFullScreenPresentation()
}

final class VideoViewController: AVPlayerViewController {
  weak var listener: VideoViewControllerListener?
}

extension VideoViewController: AVPlayerViewControllerDelegate {
  func playerViewController(_: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator _: UIViewControllerTransitionCoordinator) {
    listener?.willBeginFullScreenPresentation()
  }

  func playerViewController(_: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator _: UIViewControllerTransitionCoordinator) {
    listener?.willEndFullScreenPresentation()
  }
}
