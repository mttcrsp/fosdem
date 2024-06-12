import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  private var applicationViewModel: ApplicationViewModel?

  func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    let rootViewController: UIViewController
    do {
      #if DEBUG
      let services = try DebugServices()
      #else
      let services = try Services()
      #endif
      let applicationViewModel = ApplicationViewModel(dependencies: services)
      let applicationViewController = ApplicationViewController(viewModel: applicationViewModel, dependencies: services)
      self.applicationViewModel = applicationViewModel
      rootViewController = applicationViewController
    } catch {
      let errorViewController = ErrorViewController()
      errorViewController.showsAppStoreButton = true
      errorViewController.delegate = self
      rootViewController = errorViewController
    }

    let window = UIWindow()
    window.tintColor = .label
    window.rootViewController = rootViewController
    window.makeKeyAndVisible()
    self.window = window

    return true
  }

  func applicationDidBecomeActive(_: UIApplication) {
    applicationViewModel?.applicationDidBecomeActive()
  }

  func applicationWillResignActive(_: UIApplication) {
    applicationViewModel?.applicationWillResignActive()
  }
}

extension AppDelegate: ErrorViewControllerDelegate {
  func errorViewControllerDidTapAppStore(_: ErrorViewController) {
    if let url = URL.fosdemAppStore {
      UIApplication.shared.open(url)
    }
  }
}
