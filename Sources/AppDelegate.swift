import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    private lazy var applicationController = ApplicationController()

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        #if DEBUG
            guard !isRunningUnitTests else { return false }
        #endif

        window = UIWindow()
        window?.rootViewController = applicationController.makeRootViewController()
        window?.makeKeyAndVisible()

        return true
    }

    #if DEBUG
        private var isRunningUnitTests: Bool {
            CommandLine.arguments.contains("-ApplePersistenceIgnoreState")
        }
    #endif
}
