import UIKit

extension UIAccessibility {
    static var fos_voiceOverStatusDidChangeNotification: NSNotification.Name {
        if #available(iOS 11.0, *) {
            return UIAccessibility.voiceOverStatusDidChangeNotification
        } else {
            return NSNotification.Name(rawValue: UIAccessibilityVoiceOverStatusChanged)
        }
    }
}
