@testable
import Fosdem
import MapKit
import SnapshotTesting
import XCTest

final class MapRootViewControllerTests: XCTestCase {
  func testAppearance() throws {
    let delegate = ContainerViewControllerDelegateMock()
    delegate.containerViewControllerHandler = { containerViewController, _ in
      guard let view = containerViewController.view else { return .zero }

      var rect = CGRect()
      rect.size = CGSize(width: 320, height: 320)
      rect.origin.x = view.layoutMargins.left
      rect.origin.y = view.layoutMargins.left + view.layoutMargins.top
      return rect
    }
    delegate.containerViewControllerScrollDirectionForHandler = { _, _ in
      .horizontal
    }

    let containerViewController = ContainerViewController()
    containerViewController.containerDelegate = delegate
    containerViewController.masterViewController = makeViewController(with: .red)
    containerViewController.detailViewController = makeViewController(with: .blue)
    assertSnapshot(matching: containerViewController, as: .image(on: .iPadPro11))
    assertSnapshot(matching: containerViewController, as: .image(on: .iPhone8Plus))

    containerViewController.setDetailViewControllerVisible(true, animated: false)
    assertSnapshot(matching: containerViewController, as: .image(on: .iPadPro11))
    assertSnapshot(matching: containerViewController, as: .image(on: .iPhone8Plus))

    containerViewController.setDetailViewControllerVisible(false, animated: false)
    assertSnapshot(matching: containerViewController, as: .image(on: .iPadPro11))
    assertSnapshot(matching: containerViewController, as: .image(on: .iPhone8Plus))

    containerViewController.setDetailViewControllerVisible(true, animated: true)
    assertSnapshot(matching: containerViewController, as: .image(on: .iPadPro11))
    assertSnapshot(matching: containerViewController, as: .image(on: .iPhone8Plus))

    containerViewController.masterViewController = makeViewController(with: .green)
    containerViewController.detailViewController = makeViewController(with: .yellow)
    assertSnapshot(matching: containerViewController, as: .image(on: .iPhone8Plus))
  }

  func testScrolling() throws {
    let delegate = ContainerViewControllerDelegateMock()
    delegate.containerViewControllerHandler = { containerViewController, _ in
      guard let view = containerViewController.view else { return .zero }

      var rect = CGRect()
      rect.size = CGSize(width: view.bounds.width, height: 200)
      rect.origin.y = view.bounds.height - rect.size.height
      return rect
    }
    delegate.containerViewControllerScrollDirectionForHandler = { _, _ in
      .vertical
    }

    let containerViewController = ContainerViewController()
    containerViewController.containerDelegate = delegate
    containerViewController.masterViewController = makeViewController(with: .red)
    containerViewController.detailViewController = makeViewController(with: .blue)
    assertSnapshot(matching: containerViewController, as: .image(on: .iPhone8Plus))

    let scrollView = try XCTUnwrap(containerViewController.view.findSubview(ofType: UIScrollView.self))

    func simulateScroll(to targetContentOffset: CGPoint, with velocity: CGPoint) -> CGPoint {
      containerViewController.setDetailViewControllerVisible(true, animated: false)

      var targetContentOffset = targetContentOffset
      withUnsafeMutablePointer(to: &targetContentOffset) { targetContentOffset in
        containerViewController.scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
        containerViewController.scrollViewDidEndDecelerating(scrollView)
      }
      return targetContentOffset
    }

    var offset = CGPoint.zero

    offset = simulateScroll(to: CGPoint(x: 0, y: 99), with: .zero)
    XCTAssertEqual(offset, CGPoint(x: 0, y: 0))
    XCTAssertEqual(delegate.containerViewControllerDidHideCallCount, 0)

    offset = simulateScroll(to: CGPoint(x: 0, y: 101), with: .zero)
    XCTAssertEqual(offset, CGPoint(x: 0, y: 200))

    offset = simulateScroll(to: CGPoint(x: 0, y: 99), with: CGPoint(x: 0, y: 100))
    XCTAssertEqual(offset, CGPoint(x: 0, y: 200))

    delegate.containerViewControllerHandler = { containerViewController, _ in
      guard let view = containerViewController.view else { return .zero }

      var rect = CGRect()
      rect.size = CGSize(width: 200, height: view.bounds.height)
      return rect
    }
    delegate.containerViewControllerScrollDirectionForHandler = { _, _ in
      .horizontal
    }

    containerViewController.setDetailViewControllerVisible(true, animated: false)
    assertSnapshot(matching: containerViewController, as: .image(on: .iPhone8Plus(.landscape)))

    offset = simulateScroll(to: CGPoint(x: 99, y: 0), with: .zero)
    XCTAssertEqual(offset, CGPoint(x: 0, y: 0))

    offset = simulateScroll(to: CGPoint(x: 101, y: 0), with: .zero)
    XCTAssertEqual(offset, CGPoint(x: 200, y: 0))

    offset = simulateScroll(to: CGPoint(x: 99, y: 0), with: CGPoint(x: 100, y: 0))
    XCTAssertEqual(offset, CGPoint(x: 200, y: 0))
  }

  private func makeViewController(with backgroundColor: UIColor) -> UIViewController {
    let viewController = UIViewController()
    viewController.view.backgroundColor = backgroundColor
    return viewController
  }
}
