import AVFAudio
import AVFoundation
import CoreLocation
import RIBs
import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  private var pendingNetworkRequests = 0 {
    didSet { didChangePendingNetworkRequests() }
  }

  private var rootRouter: LaunchRouting?

  func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    let window = UIWindow()
    window.tintColor = .fos_label
    self.window = window

    do {
      let services = try makeServices()
      let rootBuilder = RootBuilder(dependency: services)
      let rootRouter = rootBuilder.build()
      self.rootRouter = rootRouter
      rootRouter.launch(from: window)
    } catch {
      print(error)
    }

    return true
  }

  private func didChangePendingNetworkRequests() {
    #if !targetEnvironment(macCatalyst)
    UIApplication.shared.isNetworkActivityIndicatorVisible = pendingNetworkRequests > 0
    #endif
  }

  private func makeServices() throws -> Services {
    #if DEBUG
    let services = try DebugServices()
    #else
    let services = try Services()
    #endif
    services.networkService.delegate = self
    return services
  }

  func makeErrorViewController() -> ErrorViewController {
    let errorViewController = ErrorViewController()
    errorViewController.showsAppStoreButton = true
    errorViewController.delegate = self
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

extension AppDelegate: ErrorViewControllerDelegate {
  func errorViewControllerDidTapAppStore(_: ErrorViewController) {
    if let url = URL.fosdemAppStore {
      UIApplication.shared.open(url)
    }
  }
}
