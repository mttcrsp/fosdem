import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    private var applicationController: ApplicationController? {
        window?.rootViewController as? ApplicationController
    }

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        #if DEBUG
            guard !isRunningUnitTests else { return false }
        #endif

        let rootViewController: UIViewController
        do {
            rootViewController = ApplicationController(services: try .init())
        } catch {
            rootViewController = ErrorController()
        }

        let window = Window()
        window.configure()
        window.configureAppearanceProxies()
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
        self.window = window

        return true
    }

    func applicationDidBecomeActive(_: UIApplication) {
        applicationController?.applicationDidBecomeActive()
    }
}

#if DEBUG
    private extension AppDelegate {
        var isRunningUnitTests: Bool {
            CommandLine.arguments.contains("-ApplePersistenceIgnoreState")
        }
    }
#endif
