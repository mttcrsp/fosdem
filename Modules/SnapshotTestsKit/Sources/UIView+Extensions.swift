import UIKit

public extension UIView {
  func findSubview<Subview: UIView>(ofType type: Subview.Type, accessibilityIdentifier: String) -> Subview? {
    findSubview(ofType: type, matching: { subview in subview.accessibilityIdentifier == accessibilityIdentifier })
  }

  func findSubview<Subview: UIView>(ofType type: Subview.Type, accessibilityLabel: String) -> Subview? {
    findSubview(ofType: type, matching: { subview in subview.accessibilityLabel == accessibilityLabel })
  }

  func findSubview<Subview: UIView>(ofType _: Subview.Type, matching predicate: (Subview) -> Bool = { _ in true }) -> Subview? {
    var unvisited: Set<UIView> = [self]

    while let subview = unvisited.first {
      unvisited.removeFirst()
      unvisited.formUnion(subview.subviews)

      if let subview = subview as? Subview, predicate(subview) {
        return subview
      }
    }

    return nil
  }
}
