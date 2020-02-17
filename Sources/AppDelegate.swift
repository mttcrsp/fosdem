import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    lazy var window: UIWindow? = UIWindow()

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        #if DEBUG
            guard !isRunningUnitTests else { return false }
        #endif

        do {
            window?.rootViewController = ApplicationController(services: try .init())
            window?.makeKeyAndVisible()
        } catch {
            window?.rootViewController = ErrorController()
            window?.makeKeyAndVisible()
        }

        return true
    }
}

#if DEBUG
    private extension AppDelegate {
        var isRunningUnitTests: Bool {
            CommandLine.arguments.contains("-ApplePersistenceIgnoreState")
        }
    }
#endif
