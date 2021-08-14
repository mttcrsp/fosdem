import UIKit

extension UIAlertController {
  static func makeErrorController(withHandler handler: (() -> Void)? = nil) -> UIAlertController {
    let title = L10n.Error.Alert.title
    let message = L10n.Error.Alert.message
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

    let dismissTitle = L10n.Error.dismiss
    let dismissAction = UIAlertAction(title: dismissTitle, style: .default) { _ in handler?() }
    alertController.addAction(dismissAction)

    return alertController
  }
}
