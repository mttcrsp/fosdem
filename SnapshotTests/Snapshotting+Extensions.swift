@testable
import Fosdem
import SnapshotTesting
import UIKit
import XCTest

extension Snapshotting where Value: UIViewController, Format == UIImage {
  static func presentingViewController(perform presentation: @escaping () -> Void) -> Snapshotting {
    Snapshotting<UIImage, UIImage>.image.pullback { presenting in
      let window = UIWindow()
      window.rootViewController = presenting
      window.makeKeyAndVisible()

      UIView.performWithoutAnimation(presentation)

      let predicate = NSPredicate { _, _ in presenting.presentedViewController != nil }
      let predicateExpectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
      XCTWaiter().wait(for: [predicateExpectation], timeout: 1)

      return UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
        window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
      }
    }
  }
}
