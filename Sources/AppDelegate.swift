import RIBs
import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  private var rootRouter: LaunchRouting?

  func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    registerProviderFactories()

    let window = UIWindow()
    window.tintColor = .fos_label
    self.window = window

    let rootComponent = RootComponent()
    let rootBuilder = RootBuilder(componentBuilder: { rootComponent })
    let rootRouter = rootBuilder.build()
    self.rootRouter = rootRouter
    rootRouter.launch(from: window)

    return true
  }
}
