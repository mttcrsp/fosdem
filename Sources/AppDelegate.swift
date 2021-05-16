import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    #if DEBUG
    if ProcessInfo.processInfo.isRunningUnitTests {
      return false
    }
    #endif

    if #available(iOS 13.0, *) {
      // handled by SceneDelegate
    } else {
      let window = UIWindow()
      application.start(from: window)
      self.window = window
    }

    #if DEBUG
    if ProcessInfo.processInfo.isRunningUITests {
      window?.layer.speed = 100
    }
    #endif

    return true
  }

  @available(iOS 13.0, *)
  func application(_: UIApplication, configurationForConnecting _: UISceneSession, options _: UIScene.ConnectionOptions) -> UISceneConfiguration {
    let configuration = UISceneConfiguration(name: "Main", sessionRole: .windowApplication)
    configuration.delegateClass = SceneDelegate.self
    return configuration
  }
}

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  private var services: Services?

  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options _: UIScene.ConnectionOptions) {
    guard let windowScene = scene as? UIWindowScene else { return }

    let window = UIWindow(windowScene: windowScene)
    UIApplication.shared.start(from: window)
    self.window = window

    let activitiesService = ActivitiesService()
    if let userActivity = session.stateRestorationActivity, let viewController = activitiesService.makeViewController(for: userActivity) {
      window.rootViewController?.present(viewController, animated: true)
    }
  }

  func stateRestorationActivity(for _: UIScene) -> NSUserActivity? {
    guard let window = window, let rootViewController = window.rootViewController else { return nil }

    var visitedViewControllers: [UIViewController] = []
    var unvisitedViewControllers = [rootViewController]
    while !unvisitedViewControllers.isEmpty {
      let viewController = unvisitedViewControllers.removeFirst()

      if let userActivity = viewController.userActivity {
        userActivity.persistentIdentifier = "state-restoration"
        return userActivity
      }

      visitedViewControllers.append(viewController)

      for child in viewController.children {
        unvisitedViewControllers.append(child)
      }
    }

    return nil
  }
}

private extension UIApplication {
  private static var servicesKey = 0

  var services: Services? {
    get { objc_getAssociatedObject(self, &UIApplication.servicesKey) as? Services }
    set { objc_setAssociatedObject(self, &UIApplication.servicesKey, newValue as Services?, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
  }

  private static var pendingNetworkRequestsKey = 0

  var pendingNetworkRequests: Int {
    get { objc_getAssociatedObject(self, &UIApplication.pendingNetworkRequestsKey) as? Int ?? 0 }
    set { objc_setAssociatedObject(self, &UIApplication.pendingNetworkRequestsKey, newValue as Int?, .OBJC_ASSOCIATION_ASSIGN) }
  }

  func start(from window: UIWindow) {
    let rootViewController: UIViewController
    do {
      rootViewController = ApplicationController(dependencies: try (services ?? (try Services())))
    } catch {
      rootViewController = makeErrorViewController()
    }

    window.tintColor = .fos_label
    window.rootViewController = rootViewController
    window.makeKeyAndVisible()
  }

  private func makeServices() throws -> Services {
    let services = try Services()
    services.networkService.delegate = self
    return services
  }

  private func makeErrorViewController() -> ErrorViewController {
    let errorViewController = ErrorViewController()
    errorViewController.showsAppStoreButton = true
    errorViewController.delegate = self
    return errorViewController
  }

  private func didChangePendingNetworkRequests() {
    #if !targetEnvironment(macCatalyst)
    isNetworkActivityIndicatorVisible = pendingNetworkRequests > 0
    #endif
  }
}

extension UIApplication: NetworkServiceDelegate {
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

extension UIApplication: ErrorViewControllerDelegate {
  func errorViewControllerDidTapAppStore(_: ErrorViewController) {
    if let url = URL.fosdemAppStore {
      UIApplication.shared.open(url)
    }
  }
}
