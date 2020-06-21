import UIKit

extension UIAlertController {
  static func makeErrorController() -> UIAlertController {
    let title = FOSLocalizedString("error.alert.title")
    let message = FOSLocalizedString("error.alert.message")
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

    let dismissTitle = FOSLocalizedString("error.dismiss")
    let dismissAction = UIAlertAction(title: dismissTitle, style: .default)
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
