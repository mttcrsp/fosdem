@testable
import Fosdem
import SnapshotTesting
import UIKit

extension Snapshotting where Value: UIViewController, Format == UIImage {
  static func window(performing action: @escaping () -> Void) -> Snapshotting {
    Snapshotting<UIImage, UIImage>.image.asyncPullback { vc in
      Async<UIImage> { callback in
        UIView.setAnimationsEnabled(false)
        let window = UIWindow()
        window.rootViewController = vc
        window.makeKeyAndVisible()
        action()
        DispatchQueue.main.async {
          let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
          }
          callback(image)
          UIView.setAnimationsEnabled(true)
        }
      }
    }
  }
}
