import UIKit
import XMLCoder

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    private var applicationController: ApplicationController?

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        #if DEBUG
            guard !isRunningUnitTests else { return false }
        #endif

        guard let url = Bundle.main.url(forResource: "2020", withExtension: "xml"), let data = try? Data(contentsOf: url), let schedule = try? XMLDecoder.default.decode(Schedule.self, from: data) else { return false }

        applicationController = ApplicationController(schedule: schedule)

        window = UIWindow()
        window?.rootViewController = applicationController?.makeRootViewController()
        window?.makeKeyAndVisible()

        return true
    }

    #if DEBUG
        private var isRunningUnitTests: Bool {
            CommandLine.arguments.contains("-ApplePersistenceIgnoreState")
        }
    #endif
}
