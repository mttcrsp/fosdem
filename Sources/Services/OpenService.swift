import UIKit

final class OpenService {
  private let application: OpenServiceApplication

  init(application: OpenServiceApplication = UIApplication.shared) {
    self.application = application
  }

  func open(_ url: URL, completion: ((Bool) -> Void)?) {
    application.open(url, options: [:], completionHandler: completion)
  }
}

/// @mockable
protocol OpenServiceProtocol {
  func open(_ url: URL, completion: ((Bool) -> Void)?)
}

extension OpenService: OpenServiceProtocol {}

/// @mockable
protocol OpenServiceApplication {
  func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey: Any], completionHandler completion: ((Bool) -> Void)?)
}

extension UIApplication: OpenServiceApplication {}
