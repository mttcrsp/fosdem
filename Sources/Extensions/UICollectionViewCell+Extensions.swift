import UIKit

extension UICollectionViewCell {
    static var reuseIdentifier: String {
        .init(describing: self)
    }
}
