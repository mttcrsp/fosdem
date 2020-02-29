import UIKit

extension UITableViewCell {
    static var reuseIdentifier: String {
        .init(describing: self)
    }
}
