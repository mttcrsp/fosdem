import UIKit

/// @mockable
protocol MapContainerViewControllerDelegate: AnyObject {
  func containerViewController(_ containerViewController: MapContainerViewController, rectFor detailViewController: UIViewController) -> CGRect
  func containerViewController(_ containerViewController: MapContainerViewController, scrollDirectionFor detailViewController: UIViewController) -> MapContainerViewController.ScrollDirection
  func containerViewController(_ containerViewController: MapContainerViewController, didShow detailViewController: UIViewController)
  func containerViewController(_ containerViewController: MapContainerViewController, didHide detailViewController: UIViewController)
}

/// @mockable
extension MapContainerViewControllerDelegate {
  func containerViewController(_: MapContainerViewController, didShow _: UIViewController) {}
  func containerViewController(_: MapContainerViewController, didHide _: UIViewController) {}
}

class MapContainerViewController: UIViewController {
  enum ScrollDirection {
    case horizontal, vertical
  }

  weak var containerDelegate: MapContainerViewControllerDelegate?

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
  private lazy var detailContainerView: UIView = {
    if #available(iOS 26.0, *) {
      let effectView = UIVisualEffectView(effect: UIGlassEffect())
      effectView.cornerConfiguration = .uniformCorners(radius: 16)
      effectView.translatesAutoresizingMaskIntoConstraints = false
      return effectView
    } else {
      let view = UIView()
      view.layer.cornerRadius = 8
      view.layer.shadowRadius = 8
      view.layer.shadowOpacity = 0.2
      view.layer.shadowOffset = .zero
      view.layer.masksToBounds = true
      view.layer.shadowColor = UIColor.black.cgColor
      return view
    }
  }()

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
    scrollView.addSubview(detailContainerView)

    observer = scrollView.observe(\.contentOffset) { [weak self] _, _ in
      if let self {
        scrollView.alpha = isDetailViewControllerVisible ? 1 : 0
      }
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    masterViewController?.view.frame = view.bounds

    guard let detailViewController else { return }

    guard let delegate = containerDelegate else {
      return assertionFailure("Unable to perform layout of the detail view controller for \(self) because no \(\MapContainerViewController.containerDelegate) was set.")
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

    detailContainerView.frame.size = detailRect.size
    detailContainerView.frame.origin = .zero
    detailView.frame.size = detailContainerView.bounds.size
    switch scrollDirection {
    case .vertical:
      let offset = view.bounds.height - detailRect.maxY
      detailContainerView.frame.origin.y = detailRect.size.height + offset
    case .horizontal:
      break
    }

    updateDetailViewControllerVisibility()
  }

  override func overrideTraitCollection(forChild childViewController: UIViewController) -> UITraitCollection? {
    guard var traitCollection = super.overrideTraitCollection(forChild: childViewController) else {
      return nil
    }

    if childViewController == detailViewController {
      traitCollection = UITraitCollection(traitsFrom: [traitCollection, UITraitCollection(userInterfaceLevel: .elevated)])
    }

    return traitCollection
  }

  private func updateDetailViewControllerVisibility() {
    guard let detailView = detailViewController?.view else { return }

    let contentOffset: CGPoint = switch (scrollDirection, isDetailViewControllerVisible) {
    case (.vertical, false), (.horizontal, true):
      .zero
    case (.horizontal, false):
      CGPoint(x: scrollView.contentSize.width - detailView.frame.width, y: 0)
    case (.vertical, true):
      CGPoint(x: 0, y: scrollView.contentSize.height - detailView.frame.height)
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
      if let detailContainerView = detailContainerView as? UIVisualEffectView {
        detailView.layer.cornerRadius = 16
        detailView.layer.masksToBounds = true
        detailContainerView.contentView.addSubview(detailView)
      } else {
        detailContainerView.addSubview(detailView)
      }
      childViewController.didMove(toParent: self)
    }
  }

  func didChangeDetailViewControllerVisibility() {
    guard let detailViewController else { return }

    if isDetailViewControllerVisible {
      containerDelegate?.containerViewController(self, didShow: detailViewController)
    } else {
      containerDelegate?.containerViewController(self, didHide: detailViewController)
    }
  }
}

extension MapContainerViewController: UIScrollViewDelegate {
  func scrollViewWillEndDragging(_: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    guard let detailViewController else { return }

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
    guard let detailViewController, let window = detailViewController.view.window else { return }

    let detailView = detailViewController.view as UIView
    let detailRect = detailView.bounds

    let containedRect = detailView.convert(detailRect, to: window)
    let containerRect = window.bounds

    isDetailViewControllerVisible = containerRect.intersects(containedRect)
  }
}
