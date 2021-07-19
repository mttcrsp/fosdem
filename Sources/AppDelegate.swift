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

  func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    #if DEBUG
    if ProcessInfo.processInfo.isRunningUnitTests {
      return false
    }
    #endif

    do {
      let services = try makeServices()

      let window = UIWindow()
      window.tintColor = .fos_label
      window.rootViewController = ApplicationController(dependencies: services)
      window.makeKeyAndVisible()
      self.window = window

      #if ENABLE_UITUNNEL
      let testsService = TestsService(services: services)
      testsService.start()
      testsService.registerCustomCommands()
      testsService.speedUpAnimations(in: window)
      #endif
    } catch {
      window = UIWindow()
      window?.tintColor = .fos_label
      window?.rootViewController = makeErrorViewController()
      window?.makeKeyAndVisible()
    }

    return true
  }

  func applicationDidBecomeActive(_: UIApplication) {
    applicationController?.applicationDidBecomeActive()
  }

  func applicationWillResignActive(_: UIApplication) {
    applicationController?.applicationWillResignActive()
  }

  private func didChangePendingNetworkRequests() {
    #if !targetEnvironment(macCatalyst)
    UIApplication.shared.isNetworkActivityIndicatorVisible = pendingNetworkRequests > 0
    #endif
  }

  private func makeServices() throws -> Services {
    let services = try Services()
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
