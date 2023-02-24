import UIKit

public extension UITraitCollection {
  var fos_hasRegularSizeClasses: Bool {
    horizontalSizeClass == .regular && verticalSizeClass == .regular
  }
}
