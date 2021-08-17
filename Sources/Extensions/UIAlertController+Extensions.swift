import UIKit

extension UIAlertController {
  static func makeErrorController(withHandler handler: (() -> Void)? = nil) -> UIAlertController {
    let dismissTitle = L10n.Error.dismiss
    let dismissAction = UIAlertAction(title: dismissTitle, style: .default) { _ in handler?() }

    let title = L10n.Error.Unknown.title, message = L10n.Error.Unknown.message
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alertController.addAction(dismissAction)
    return alertController
  }

  static func makeNoInternetController(withRetryHandler handler: @escaping () -> Void) -> UIAlertController {
    let dismissTitle = L10n.Error.dismiss
    let dismissAction = UIAlertAction(title: dismissTitle, style: .cancel)

    let retryTitle = L10n.Error.retry
    let retryAction = UIAlertAction(title: retryTitle, style: .default) { _ in handler() }

    let title = L10n.Error.Internet.title, message = L10n.Error.Internet.message
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alertController.addAction(retryAction)
    alertController.addAction(dismissAction)
    return alertController
  }
}
