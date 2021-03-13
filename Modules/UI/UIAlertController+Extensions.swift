import L10n
import UIKit

public extension UIAlertController {
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

public extension UIAlertController {
  struct ConfirmConfiguration {
    public let title: String
    public let message: String
    public let confirm: String
    public let dismiss: String

    public init(title: String, message: String, confirm: String, dismiss: String) {
      self.title = title
      self.message = message
      self.confirm = confirm
      self.dismiss = dismiss
    }
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
