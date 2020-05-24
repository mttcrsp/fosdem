import UIKit

extension UIFont {
    class func fos_preferredFont(forTextStyle style: UIFont.TextStyle, withSymbolicTraits traits: UIFontDescriptor.SymbolicTraits = []) -> UIFont {
        if #available(iOS 11.0, *) {
            let descriptorOriginal = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
            let descriptor = descriptorOriginal.withSymbolicTraits(traits) ?? descriptorOriginal
            let font = UIFont(descriptor: descriptor, size: 0)
            return UIFontMetrics.default.scaledFont(for: font)
        } else {
            let traitCollection = UITraitCollection(preferredContentSizeCategory: .large)
            let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style, compatibleWith: traitCollection)
            if traits.contains(.traitBold) {
                return UIFont.boldSystemFont(ofSize: descriptor.pointSize)
            } else if traits.contains(.traitItalic) {
                return UIFont.italicSystemFont(ofSize: descriptor.pointSize)
            } else {
                return UIFont.systemFont(ofSize: descriptor.pointSize)
            }
        }
    }
}
