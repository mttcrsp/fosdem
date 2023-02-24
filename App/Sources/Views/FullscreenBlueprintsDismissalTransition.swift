import UIKit

final class FullscreenBlueprintsDismissalTransition: UIPercentDrivenInteractiveTransition, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning {
  private weak var dismissedViewController: UIViewController?

  private(set) lazy var panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panned(_:)))

  init(dismissedViewController: UIViewController) {
    self.dismissedViewController = dismissedViewController
  }

  func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    panRecognizer.state == .began && dismissed == dismissedViewController ? self : nil
  }

  func interactionControllerForDismissal(using _: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
    panRecognizer.state == .began ? self : nil
  }

  func transitionDuration(using _: UIViewControllerContextTransitioning?) -> TimeInterval {
    0.5
  }

  func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    guard let dismissedViewController = dismissedViewController else { return }

    let duration = transitionDuration(using: transitionContext)
    let dismissedView: UIView = dismissedViewController.view
    let dismissedViewTargetY = dismissedView.bounds.height

    UIView.animate(withDuration: duration, animations: {
      dismissedView.frame.origin.y = dismissedViewTargetY
    }, completion: { _ in
      let didComplete = !transitionContext.transitionWasCancelled
      if didComplete {
        dismissedView.removeFromSuperview()
      }
      transitionContext.completeTransition(didComplete)
    })
  }

  @objc private func panned(_ recognizer: UIPanGestureRecognizer) {
    guard let dismissedViewController = dismissedViewController else { return }

    switch recognizer.state {
    case .began:
      dismissedViewController.dismiss(animated: true)
      recognizer.setTranslation(.zero, in: nil)
    case .changed:
      let translation = recognizer.translation(in: nil)
      let translationPercentComplete = translation.y / dismissedViewController.view.bounds.height
      update(max(0, min(1, translationPercentComplete)))
    case .ended:
      let velocity = recognizer.velocity(in: nil)
      let initialVelocity = velocity.y
      let decelerationRate = UIScrollView.DecelerationRate.normal.rawValue
      let projection = (initialVelocity / 1000) * decelerationRate / (1 - decelerationRate)

      let translation = recognizer.translation(in: nil)
      let projectedTranslation = translation.y + projection
      let projectedPercentComplete = projectedTranslation / dismissedViewController.view.bounds.height

      if projectedPercentComplete > 0.5 {
        finish()
      } else {
        cancel()
      }
    case .cancelled, .failed:
      cancel()
    default:
      break
    }
  }
}
