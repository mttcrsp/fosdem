import UIKit

struct OpenService {
  var open: (URL, ((Bool) -> Void)?) -> Void
}

extension OpenService {
  init(application: OpenServiceApplication = UIApplication.shared) {
    open = { url, completion in
      application.open(url, options: [:], completionHandler: completion)
    }
  }
}

/// @mockable
protocol OpenServiceProtocol {
  var open: (URL, ((Bool) -> Void)?) -> Void { get }
}

extension OpenService: OpenServiceProtocol {}

/// @mockable
protocol OpenServiceApplication {
  func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey: Any], completionHandler completion: ((Bool) -> Void)?)
}

extension UIApplication: OpenServiceApplication {}

protocol HasOpenService {
  var openService: OpenServiceProtocol { get }
}
