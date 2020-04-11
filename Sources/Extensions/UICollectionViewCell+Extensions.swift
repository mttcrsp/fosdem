import UIKit

extension UICollectionViewCell {
    static var reuseIdentifier: String {
        String(describing: self)
    }
}
