import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  private var pendingNetworkRequests = 0 {
    didSet { didChangePendingNetworkRequests() }
  }

  private var applicationController: ApplicationController? {
    window?.rootViewController as? ApplicationController
  }

  func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    #if DEBUG
    guard !isRunningUnitTests else { return false }
    #endif

    let rootViewController: UIViewController
    do {
      rootViewController = ApplicationController(services: try makeServices())
    } catch {
      rootViewController = makeErrorViewController()
    }

    let window = UIWindow()
    window.tintColor = .fos_label
    window.rootViewController = rootViewController
    window.makeKeyAndVisible()
    self.window = window

    return true
  }

  func applicationDidBecomeActive(_: UIApplication) {
    applicationController?.applicationDidBecomeActive()
  }

  func applicationWillResignActive(_: UIApplication) {
    applicationController?.applicationWillResignActive()
  }

  private func didChangePendingNetworkRequests() {
    UIApplication.shared.isNetworkActivityIndicatorVisible = pendingNetworkRequests > 0
  }

  private func makeServices() throws -> Services {
    let services = try Services()
    services.networkService.delegate = self
    return services
  }

  func makeErrorViewController() -> ErrorViewController {
    let errorViewController = ErrorViewController()
    errorViewController.showsAppStoreButton = true
    return errorViewController
  }
}

extension AppDelegate: NetworkServiceDelegate {
  func networkServiceDidBeginRequest(_: NetworkService) {
    OperationQueue.main.addOperation { [weak self] in
      self?.pendingNetworkRequests += 1
    }
  }

  func networkServiceDidEndRequest(_: NetworkService) {
    OperationQueue.main.addOperation { [weak self] in
      self?.pendingNetworkRequests -= 1
    }
  }
}

#if DEBUG
private extension AppDelegate {
  var isRunningUnitTests: Bool {
    CommandLine.arguments.contains("-ApplePersistenceIgnoreState")
  }
}
#endif
