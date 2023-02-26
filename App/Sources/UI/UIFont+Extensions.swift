import UIKit

extension UIFont {
  class func fos_preferredFont(forTextStyle style: UIFont.TextStyle, withSymbolicTraits traits: UIFontDescriptor.SymbolicTraits = []) -> UIFont {
    let descriptorOriginal = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
    let descriptor = descriptorOriginal.withSymbolicTraits(traits) ?? descriptorOriginal
    let font = UIFont(descriptor: descriptor, size: 0)
    return UIFontMetrics.default.scaledFont(for: font)
  }
}
