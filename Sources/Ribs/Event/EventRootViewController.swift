import AVKit
import RIBs
import SafariServices
import UIKit

protocol EventPresentableListener: AnyObject {
  func toggleFavorite()
  func beginFullScreenPlayerPresentation()
  func endFullScreenPlayerPresentation()
}

final class EventRootViewController: EventViewController, ViewControllable {
  weak var listener: EventPresentableListener?

  private lazy var favoriteButton: UIBarButtonItem = {
    let favoriteAction = #selector(didToggleFavorite)
    let favoriteButton = UIBarButtonItem(title: nil, style: .plain, target: self, action: favoriteAction)
    return favoriteButton
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    delegate = self
    navigationItem.largeTitleDisplayMode = .never
  }
}

extension EventRootViewController: EventPresentable {
  var allowsFavoriting: Bool {
    get { navigationItem.rightBarButtonItem == favoriteButton }
    set { navigationItem.rightBarButtonItem = newValue ? favoriteButton : nil; print(newValue) }
  }

  var showsFavorite: Bool {
    get { favoriteButton.accessibilityIdentifier == "unfavorite" }
    set {
      favoriteButton.title = newValue ? L10n.Event.remove : L10n.Event.add
      favoriteButton.accessibilityIdentifier = newValue ? "unfavorite" : "favorite"
    }
  }
}

extension EventRootViewController: EventViewControllerDelegate {
  func eventViewController(_ eventViewController: EventViewController, didSelect attachment: Attachment) {
    let attachmentViewController = SFSafariViewController(url: attachment.url)
    eventViewController.present(attachmentViewController, animated: true)
  }

  func eventViewControllerDidTapLivestream(_: EventViewController) {
    if let link = event.links.first(where: \.isLivestream), let url = link.livestreamURL {
      showPlayerViewController(with: url)
    }
  }

  func eventViewControllerDidTapVideo(_: EventViewController) {
    if let video = event.video, let url = video.url {
      showPlayerViewController(with: url)
    }
  }

  private func showPlayerViewController(with url: URL) {
    let playerViewController = AVPlayerViewController()
    playerViewController.exitsFullScreenWhenPlaybackEnds = true
    playerViewController.player = AVPlayer(url: url)
    playerViewController.player?.play()
    playerViewController.delegate = self
    present(playerViewController, animated: true)
  }
}

extension EventRootViewController: AVPlayerViewControllerDelegate {
  func playerViewController(_: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator _: UIViewControllerTransitionCoordinator) {
    listener?.beginFullScreenPlayerPresentation()
  }

  func playerViewController(_: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator _: UIViewControllerTransitionCoordinator) {
    listener?.endFullScreenPlayerPresentation()
  }
}

private extension EventRootViewController {
  @objc func didToggleFavorite() {
    listener?.toggleFavorite()
  }
}
