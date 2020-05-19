import UIKit

extension UIAlertController {
    static func makeErrorController() -> UIAlertController {
        let title = NSLocalizedString("error.alert.title", comment: "")
        let message = NSLocalizedString("error.alert.message", comment: "")
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let dismissTitle = NSLocalizedString("error.dismiss", comment: "")
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
