import UIKit

protocol MoreSplitViewControllerDelegate: AnyObject {
  func splitViewController(_ splitViewController: MoreSplitViewController, didChangeTraitCollectionFrom previousTraitCollection: UITraitCollection?)
}

final class MoreSplitViewController: UISplitViewController {
  weak var moreDelegate: MoreSplitViewControllerDelegate?

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    moreDelegate?.splitViewController(self, didChangeTraitCollectionFrom: previousTraitCollection)
  }
}
