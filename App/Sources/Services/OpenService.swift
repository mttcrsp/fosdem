import UIKit

final class OpenService {
  private let application: OpenServiceApplication

  init(application: OpenServiceApplication = UIApplication.shared) {
    self.application = application
  }

  func open(_ url: URL, completion: ((Bool) -> Void)?) {
    application.open(url, completionHandler: completion)
  }
}

/// @mockable
protocol OpenServiceProtocol {
  func open(_ url: URL, completion: ((Bool) -> Void)?)
}

extension OpenService: OpenServiceProtocol {}

/// @mockable
protocol OpenServiceApplication {
  func open(_ url: URL, completionHandler completion: ((Bool) -> Void)?)
}

extension UIApplication: OpenServiceApplication {
  func open(_ url: URL, completionHandler completion: ((Bool) -> Void)?) {
    open(url, options: [:], completionHandler: completion)
  }
}

protocol HasOpenService {
  var openService: OpenServiceProtocol { get }
}
