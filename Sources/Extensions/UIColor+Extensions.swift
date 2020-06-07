import UIKit

extension UIColor {
  static var fos_systemBackground: UIColor {
    if #available(iOS 13.0, *) {
      return .systemBackground
    } else {
      return .white
    }
  }

  static var fos_tertiarySystemBackground: UIColor {
    if #available(iOS 13.0, *) {
      return .tertiarySystemBackground
    } else {
      return UIColor(red: 44 / 255, green: 44 / 255, blue: 46 / 255, alpha: 1)
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

  static var fos_quaternaryLabel: UIColor {
    if #available(iOS 13.0, *) {
      return .quaternaryLabel
    } else {
      return UIColor(red: 60 / 255, green: 60 / 255, blue: 67 / 255, alpha: 0.18)
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
