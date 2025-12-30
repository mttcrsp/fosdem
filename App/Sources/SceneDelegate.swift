import UIKit

final class SceneDelegate: UIResponder, UISceneDelegate {
  var window: UIWindow?
  private var applicationController: ApplicationController?

  func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }

    let rootViewController: UIViewController
    do {
      #if DEBUG
      let services = try DebugServices()
      #else
      let services = try Services()
      #endif
      let applicationController = ApplicationController(dependencies: services)
      self.applicationController = applicationController
      rootViewController = applicationController
    } catch {
      let errorViewController = ErrorViewController()
      errorViewController.showsAppStoreButton = true
      errorViewController.delegate = self
      rootViewController = errorViewController
    }

    let window = UIWindow(windowScene: windowScene)
    window.tintColor = .label
    window.rootViewController = rootViewController
    window.makeKeyAndVisible()
    self.window = window
  }

  func sceneDidBecomeActive(_: UIScene) {
    applicationController?.sceneDidBecomeActive()
  }

  func sceneWillResignActive(_: UIScene) {
    applicationController?.sceneWillResignActive()
  }
}

extension SceneDelegate: ErrorViewControllerDelegate {
  func errorViewControllerDidTapAppStore(_: ErrorViewController) {
    if let url = URL.fosdemAppStore {
      UIApplication.shared.open(url)
    }
  }
}
