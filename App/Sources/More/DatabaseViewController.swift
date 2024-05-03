#if DEBUG

import UIKit

extension UIAlertController {
  static func makeGenerateDatabaseController() -> UIAlertController {
    let title = "Generate database", message = "Specify the year you want to generate a database for. Check the Xcode console for the path to the generated database file."
    let alertViewController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alertViewController.addTextField { textField in
      textField.keyboardType = .numberPad
      textField.placeholder = "YYYY"
    }
    alertViewController.addAction(.init(title: "Cancel", style: .cancel))
    alertViewController.addAction(.init(title: "Generate", style: .default) { [weak alertViewController] _ in
      guard let text = alertViewController?.textFields?.first?.text, let year = Year(text) else { return }
      GenerateDatabaseService().generate(forYear: year) { dump($0) }
    })
    return alertViewController
  }

  static func makeGenerateDatabaseUnavailableController() -> UIAlertController {
    let title = "Ooops", message = "Database files can only be generated while running on a Simulator"
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alertController.addAction(.init(title: "Ok", style: .default))
    return alertController
  }
}

#endif
