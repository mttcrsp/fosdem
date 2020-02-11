import UIKit
import XMLCoder

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    private var tracksController: TracksController?

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        guard let url = Bundle.main.url(forResource: "2020", withExtension: "xml"), let data = try? Data(contentsOf: url), let schedule = try? XMLDecoder.default.decode(Schedule.self, from: data) else { return false }

        let services = Services()
        let tracksController = TracksController(schedule: schedule, dependencies: services)
        let tracksViewController = tracksController.makeTracksViewController()
        let navigationController = UINavigationController(rootViewController: tracksViewController)

        if #available(iOS 11.0, *) {
            navigationController.navigationBar.prefersLargeTitles = true
        }

        let tabBarController = UITabBarController()
        tabBarController.setViewControllers([navigationController], animated: true)

        window = UIWindow()
        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()

        self.tracksController = tracksController

        return true
    }
}
