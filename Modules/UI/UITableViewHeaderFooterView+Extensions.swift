import UIKit

public extension UITableViewHeaderFooterView {
  static var reuseIdentifier: String {
    String(describing: self)
  }
}
