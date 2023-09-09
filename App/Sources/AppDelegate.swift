import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  private var applicationController: ApplicationController? {
    window?.rootViewController as? ApplicationController
  }

  func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    let rootViewController: UIViewController
    do {
      rootViewController = ApplicationController(dependencies: try makeServices())
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

  private func makeServices() throws -> Services {
    #if DEBUG
    let services = try DebugServices()
    #else
    let services = try Services()
    #endif
    return services
  }

  func makeErrorViewController() -> ErrorViewController {
    let errorViewController = ErrorViewController()
    errorViewController.showsAppStoreButton = true
    errorViewController.delegate = self
    return errorViewController
  }
}

extension AppDelegate: ErrorViewControllerDelegate {
  func errorViewControllerDidTapAppStore(_: ErrorViewController) {
    if let url = URL.fosdemAppStore {
      UIApplication.shared.open(url)
    }
  }
}
