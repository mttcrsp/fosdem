import L10n
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

extension UIAlertController {
  struct ConfirmConfiguration {
    let title: String
    let message: String
    let confirm: String
    let dismiss: String
  }

  static func makeConfirmController(with configuration: ConfirmConfiguration, dismissHandler: @escaping () -> Void = {}, confirmHandler: @escaping () -> Void) -> UIAlertController {
    let dismissAction = UIAlertAction(title: configuration.dismiss, style: .cancel) { _ in dismissHandler() }
    let confirmAction = UIAlertAction(title: configuration.confirm, style: .default) { _ in confirmHandler() }
    let alertController = UIAlertController(title: configuration.title, message: configuration.message, preferredStyle: .alert)
    alertController.addAction(confirmAction)
    alertController.addAction(dismissAction)
    return alertController
  }
}
