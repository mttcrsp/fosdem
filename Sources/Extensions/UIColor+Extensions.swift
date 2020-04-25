import UIKit

extension UIColor {
    static var fos_systemBackground: UIColor {
        if #available(iOS 13.0, *) {
            return .systemBackground
        } else {
            return .white
        }
    }

    static var fos_systemGroupedBackground: UIColor {
        if #available(iOS 13.0, *) {
            return .systemGroupedBackground
        } else {
            return UIColor(red: 242 / 255, green: 242 / 255, blue: 247 / 255, alpha: 1)
        }
    }

    static var fos_secondarySystemGroupedBackground: UIColor {
        if #available(iOS 13.0, *) {
            return .secondarySystemGroupedBackground
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

    static var fos_systemGray4: UIColor {
        if #available(iOS 13.0, *) {
            return .systemGray4
        } else {
            return UIColor(red: 209 / 255, green: 209 / 255, blue: 214 / 255, alpha: 1)
        }
    }

    static var fos_separator: UIColor {
        if #available(iOS 13.0, *) {
            return .separator
        } else {
            return UIColor(red: 198 / 255, green: 198 / 255, blue: 200 / 255, alpha: 1)
        }
    }
}

extension UIColor {
    func adjustingBrightness(byFactor factor: CGFloat) -> UIColor {
        var hue = CGFloat(0), saturation = CGFloat(0), brightness = CGFloat(0), alpha = CGFloat(0)
        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        brightness = max(0, min(1, brightness * factor))
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }
}
