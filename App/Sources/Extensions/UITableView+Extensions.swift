import UIKit

extension UITableView.Style {
  static var fos_grouped: UITableView.Style {
    if #available(iOS 26.0, *) {
      .insetGrouped
    } else {
      .grouped
    }
  }
}
