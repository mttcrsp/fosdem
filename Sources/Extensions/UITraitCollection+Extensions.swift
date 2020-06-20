import UIKit

extension UITraitCollection {
  var fos_hasRegularSizeClasses: Bool {
    horizontalSizeClass == .regular && verticalSizeClass == .regular
  }
}
