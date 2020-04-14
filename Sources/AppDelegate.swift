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
            rootViewController = ApplicationController(services: try Services())
        } catch {
            rootViewController = ErrorController()
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
}

#if DEBUG
    private extension AppDelegate {
        var isRunningUnitTests: Bool {
            CommandLine.arguments.contains("-ApplePersistenceIgnoreState")
        }
    }
#endif
