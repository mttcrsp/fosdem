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
            return .init(red: 60 / 255, green: 60 / 255, blue: 67 / 255, alpha: 60 / 255)
        }
    }
}

extension UIColor {
    func adjustingBrightness(byFactor factor: CGFloat) -> UIColor {
        var hue = CGFloat(0), saturation = CGFloat(0), brightness = CGFloat(0), alpha = CGFloat(0)
        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        brightness = max(0, min(1, brightness * factor))
        return .init(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }
}
