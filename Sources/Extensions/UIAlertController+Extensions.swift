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
