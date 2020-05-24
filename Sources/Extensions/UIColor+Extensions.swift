import UIKit

extension UIColor {
    static var fos_systemBackground: UIColor {
        if #available(iOS 13.0, *) {
            return .systemBackground
        } else {
            return .white
        }
    }

    static var fos_label: UIColor {
        if #available(iOS 13.0, *) {
            return .label
        } else {
            return .black
        }
    }

    static var fos_secondaryLabel: UIColor {
        if #available(iOS 13.0, *) {
            return .secondaryLabel
        } else {
            return UIColor(red: 60 / 255, green: 60 / 255, blue: 67 / 255, alpha: 0.6)
        }
    }
}
