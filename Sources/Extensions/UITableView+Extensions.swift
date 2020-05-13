import UIKit

extension UITableView.Style {
    static var fos_insetGrouped: UITableView.Style {
        if #available(iOS 13.0, *) {
            return .insetGrouped
        } else {
            return .grouped
        }
    }
}
