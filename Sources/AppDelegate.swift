import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        #if DEBUG
            guard !isRunningUnitTests else { return false }
        #endif

        window = UIWindow()
        window?.rootViewController = ApplicationController(services: .init())
        window?.makeKeyAndVisible()

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
