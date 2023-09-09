import UIKit

struct OpenClient {
  var open: (URL, ((Bool) -> Void)?) -> Void
}

extension OpenClient {
  init(application: OpenClientApplication = UIApplication.shared) {
    open = { url, completion in
      application.open(url, options: [:], completionHandler: completion)
    }
  }
}

/// @mockable
protocol OpenClientProtocol {
  var open: (URL, ((Bool) -> Void)?) -> Void { get }
}

extension OpenClient: OpenClientProtocol {}

/// @mockable
protocol OpenClientApplication {
  func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey: Any], completionHandler completion: ((Bool) -> Void)?)
}

extension UIApplication: OpenClientApplication {}
