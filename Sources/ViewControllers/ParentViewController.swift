import UIKit

protocol ParentViewControllerDelegate: AnyObject {
  func parentViewController(_ parentViewController: UIViewController, didChangeTraitCollectionFrom previousTraitCollection: UITraitCollection?)
}

final class ParentViewController: UIViewController {
  weak var delegate: ParentViewControllerDelegate?

  private(set) weak var childViewController: UIViewController?

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    delegate?.parentViewController(self, didChangeTraitCollectionFrom: previousTraitCollection)
  }

  func setChild(_ childViewController: UIViewController?) {
    let oldViewController = self.childViewController
    let newViewController = childViewController

    if let viewController = oldViewController {
      viewController.willMove(toParent: nil)
      viewController.view.removeFromSuperview()
      viewController.removeFromParent()
    }

    if let viewController = newViewController {
      self.childViewController = childViewController

      addChild(viewController)
      view.addSubview(viewController.view)
      viewController.view.translatesAutoresizingMaskIntoConstraints = false
      viewController.didMove(toParent: self)

      NSLayoutConstraint.activate([
        viewController.view.topAnchor.constraint(equalTo: view.topAnchor),
        viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        viewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        viewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      ])
    }
  }
}
