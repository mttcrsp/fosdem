import UIKit

/// @mockable
protocol ContainerViewControllerDelegate: AnyObject {
  func containerViewController(_ containerViewController: ContainerViewController, rectFor detailViewController: UIViewController) -> CGRect
  func containerViewController(_ containerViewController: ContainerViewController, scrollDirectionFor detailViewController: UIViewController) -> ContainerViewController.ScrollDirection
  func containerViewController(_ containerViewController: ContainerViewController, didShow detailViewController: UIViewController)
  func containerViewController(_ containerViewController: ContainerViewController, didHide detailViewController: UIViewController)
}

/// @mockable
extension ContainerViewControllerDelegate {
  func containerViewController(_: ContainerViewController, didShow _: UIViewController) {}
  func containerViewController(_: ContainerViewController, didHide _: UIViewController) {}
}

class ContainerViewController: UIViewController {
  enum ScrollDirection {
    case horizontal, vertical
  }

  weak var containerDelegate: ContainerViewControllerDelegate?

  weak var masterViewController: UIViewController? {
    didSet { didChangeMasterViewController(from: oldValue, to: masterViewController) }
  }

  weak var detailViewController: UIViewController? {
    didSet { didChangeDetailViewController(from: oldValue, to: detailViewController) }
  }

  private(set) var isDetailViewControllerVisible = false {
    didSet { didChangeDetailViewControllerVisibility() }
  }

  private var scrollDirection: ScrollDirection {
    if detailViewController?.view.frame.width == scrollView.contentSize.width {
      return .vertical
    } else if detailViewController?.view.frame.height == scrollView.contentSize.height {
      return .horizontal
    } else {
      assertionFailure("Attempting to determine scroll direction before detail view controller for \(self) was configured")
      return .horizontal
    }
  }

  private lazy var scrollView = UIScrollView()

  private var observer: NSObjectProtocol?

  func setDetailViewControllerVisible(_ visible: Bool, animated: Bool) {
    isDetailViewControllerVisible = visible

    let animation = updateDetailViewControllerVisibility

    if animated, !UIAccessibility.isReduceMotionEnabled {
      let animator = UIViewPropertyAnimator(duration: 0.3, timingParameters: UISpringTimingParameters())
      animator.addAnimations(animation)
      animator.startAnimation()
    } else {
      UIView.performWithoutAnimation(animation)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.addSubview(scrollView)
    scrollView.delegate = self
    scrollView.clipsToBounds = false
    scrollView.decelerationRate = .fast
    scrollView.showsVerticalScrollIndicator = false
    scrollView.showsHorizontalScrollIndicator = false

    observer = scrollView.observe(\.contentOffset) { [weak self] _, _ in
      if let self = self {
        self.scrollView.alpha = self.isDetailViewControllerVisible ? 1 : 0
      }
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    masterViewController?.view.frame = view.bounds

    guard let detailViewController = detailViewController else { return }

    guard let delegate = containerDelegate else {
      return assertionFailure("Unable to perform layout of the detail view controller for \(self) because no \(\ContainerViewController.containerDelegate) was set.")
    }

    let scrollDirection = delegate.containerViewController(self, scrollDirectionFor: detailViewController)
    let detailRect = delegate.containerViewController(self, rectFor: detailViewController)
    let detailView = detailViewController.view as UIView

    scrollView.frame = detailRect
    scrollView.contentSize = detailRect.size
    switch scrollDirection {
    case .vertical:
      let offset = view.bounds.height - detailRect.maxY
      scrollView.contentSize.height *= 2
      scrollView.contentSize.height += offset
    case .horizontal:
      let offset = detailRect.minX
      scrollView.contentSize.width *= 2
      scrollView.contentSize.width += offset
    }

    detailView.frame.size = detailRect.size
    detailView.frame.origin = .zero
    switch scrollDirection {
    case .vertical:
      let offset = view.bounds.height - detailRect.maxY
      detailView.frame.origin.y = detailRect.size.height + offset
    case .horizontal:
      break
    }

    updateDetailViewControllerVisibility()
  }

  override func overrideTraitCollection(forChild childViewController: UIViewController) -> UITraitCollection? {
    guard var traitCollection = super.overrideTraitCollection(forChild: childViewController) else {
      return nil
    }

    if #available(iOS 13.0, *), childViewController == detailViewController {
      traitCollection = UITraitCollection(traitsFrom: [traitCollection, UITraitCollection(userInterfaceLevel: .elevated)])
    }

    return traitCollection
  }

  private func updateDetailViewControllerVisibility() {
    guard let detailView = detailViewController?.view else { return }

    let contentOffset: CGPoint

    switch (scrollDirection, isDetailViewControllerVisible) {
    case (.vertical, false), (.horizontal, true):
      contentOffset = .zero
    case (.horizontal, false):
      contentOffset = CGPoint(x: scrollView.contentSize.width - detailView.frame.width, y: 0)
    case (.vertical, true):
      contentOffset = CGPoint(x: 0, y: scrollView.contentSize.height - detailView.frame.height)
    }

    scrollView.contentOffset = contentOffset
  }

  private func didChangeMasterViewController(from old: UIViewController?, to new: UIViewController?) {
    if let childViewController = old {
      childViewController.willMove(toParent: nil)
      childViewController.view.removeFromSuperview()
      childViewController.removeFromParent()
    }

    if let childViewController = new {
      addChild(childViewController)
      view.insertSubview(childViewController.view, belowSubview: scrollView)
      childViewController.didMove(toParent: self)
    }
  }

  private func didChangeDetailViewController(from old: UIViewController?, to new: UIViewController?) {
    if let childViewController = old {
      childViewController.willMove(toParent: nil)
      childViewController.view.removeFromSuperview()
      childViewController.removeFromParent()
    }

    if let childViewController = new {
      addChild(childViewController)

      let detailView: UIView = childViewController.view
      detailView.layer.cornerRadius = 8
      detailView.layer.shadowRadius = 8
      detailView.layer.shadowOpacity = 0.2
      detailView.layer.shadowOffset = .zero
      detailView.layer.masksToBounds = true
      detailView.layer.shadowColor = UIColor.black.cgColor
      scrollView.addSubview(detailView)

      childViewController.didMove(toParent: self)
    }
  }

  func didChangeDetailViewControllerVisibility() {
    guard let detailViewController = detailViewController else { return }

    if isDetailViewControllerVisible {
      containerDelegate?.containerViewController(self, didShow: detailViewController)
    } else {
      containerDelegate?.containerViewController(self, didHide: detailViewController)
    }
  }
}

extension ContainerViewController: UIScrollViewDelegate {
  func scrollViewWillEndDragging(_: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    guard let detailViewController = detailViewController else { return }

    switch scrollDirection {
    case .vertical:
      verticalDetailViewController(detailViewController, willEndDraggingWithVelocity: velocity, targetContentOffset: targetContentOffset)
    case .horizontal:
      horizontalDetailViewController(detailViewController, willEndDraggingWithVelocity: velocity, targetContentOffset: targetContentOffset)
    }
  }

  private func verticalDetailViewController(_ detailViewController: UIViewController, willEndDraggingWithVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    let detailSize = detailViewController.view.frame.size

    let target = targetContentOffset.pointee.y
    let y1 = scrollView.contentSize.height - detailSize.height
    let y2 = 0 as CGFloat

    let preferY1: Bool
    if velocity.y == 0 {
      let distance1 = abs(target - y1)
      let distance2 = abs(target - y2)
      preferY1 = distance1 < distance2
    } else {
      preferY1 = velocity.y > 0
    }

    targetContentOffset.pointee = CGPoint(x: 0, y: preferY1 ? y1 : y2)
  }

  private func horizontalDetailViewController(_ detailViewController: UIViewController, willEndDraggingWithVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    let detailSize = detailViewController.view.frame.size

    let target = targetContentOffset.pointee.x
    let x1 = scrollView.contentSize.width - detailSize.width
    let x2 = 0 as CGFloat

    let preferX1: Bool
    if velocity.x == 0 {
      let distance1 = abs(target - x1)
      let distance2 = abs(target - x2)
      preferX1 = distance1 < distance2
    } else {
      preferX1 = velocity.x > 0
    }

    targetContentOffset.pointee = CGPoint(x: preferX1 ? x1 : x2, y: 0)
  }

  func scrollViewDidEndDecelerating(_: UIScrollView) {
    guard let detailViewController = detailViewController, let window = detailViewController.view.window else { return }

    let detailView = detailViewController.view as UIView
    let detailRect = detailView.bounds

    let containedRect = detailView.convert(detailRect, to: window)
    let containerRect = window.bounds

    isDetailViewControllerVisible = containerRect.intersects(containedRect)
  }
}
