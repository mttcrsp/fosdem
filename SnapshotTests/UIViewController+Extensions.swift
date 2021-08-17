import UIKit

extension UIViewController {
  func findChild<Child: UIViewController>(ofType _: Child.Type) -> Child? {
    var unvisited: Set<UIViewController> = [self]

    while let child = unvisited.first {
      unvisited.removeFirst()
      unvisited.formUnion(child.children)

      if let child = child as? Child {
        return child
      }
    }

    return nil
  }
}
