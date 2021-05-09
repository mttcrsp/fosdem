import UIKit

class UIViewControllerTransitionCoordinatorMock: NSObject, UIViewControllerTransitionCoordinator {
  var isAnimated: Bool = false
  var presentationStyle: UIModalPresentationStyle = .fullScreen
  var initiallyInteractive: Bool = false
  var isInterruptible: Bool = false
  var isInteractive: Bool = false
  var isCancelled: Bool = false
  var transitionDuration: TimeInterval = 0
  var percentComplete: CGFloat = 0
  var completionVelocity: CGFloat = 0
  var completionCurve: UIView.AnimationCurve = .linear

  func animate(alongsideTransition _: ((UIViewControllerTransitionCoordinatorContext) -> Void)?, completion _: ((UIViewControllerTransitionCoordinatorContext) -> Void)? = nil) -> Bool { false }
  func animateAlongsideTransition(in _: UIView?, animation _: ((UIViewControllerTransitionCoordinatorContext) -> Void)?, completion _: ((UIViewControllerTransitionCoordinatorContext) -> Void)? = nil) -> Bool { false }

  func notifyWhenInteractionEnds(_: @escaping (UIViewControllerTransitionCoordinatorContext) -> Void) {}
  func notifyWhenInteractionChanges(_: @escaping (UIViewControllerTransitionCoordinatorContext) -> Void) {}

  func viewController(forKey _: UITransitionContextViewControllerKey) -> UIViewController? { nil }
  func view(forKey _: UITransitionContextViewKey) -> UIView? { nil }

  var containerView = UIView()
  var targetTransform: CGAffineTransform = .identity
}
