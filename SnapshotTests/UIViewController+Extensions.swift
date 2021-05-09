import InterposeKit
import UIKit

extension UIViewController {
  final class PresentArguments {
    var viewControllerToPresent: UIViewController?
    var animated: Bool?
    var completion: (() -> Void)?

    fileprivate var cleanup: (() -> Void)?
    deinit { cleanup?() }
  }

  // Returns an object that records the set of arguments used by the most recent
  // `present(_:animated:completion:)` invocation.
  func fos_mockPresent() throws -> PresentArguments {
    let args = PresentArguments()

    let result = try hook(#selector(UIViewController.present(_:animated:completion:))) {
      (
        _: TypedHook<
        @convention(c) (AnyObject, Selector, UIViewController, Bool, (() -> Void)?) -> Void,
        @convention(block) (AnyObject, UIViewController, Bool, (() -> Void)?) -> Void
        >
      ) in { _, viewControllerToPresent, animated, completion in
          args.viewControllerToPresent = viewControllerToPresent
          args.animated = animated
          args.completion = completion
        }
    }

    args.cleanup = {
      result.cleanup()
      _ = try? result.revert()
    }

    return args
  }
}
