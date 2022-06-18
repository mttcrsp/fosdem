import AVFAudio
import AVFoundation
import CoreLocation
import RIBs
import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  private var pendingNetworkRequests = 0 {
    didSet { didChangePendingNetworkRequests() }
  }

  private var rootRouter: LaunchRouting?

  func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    let window = UIWindow()
    window.tintColor = .fos_label
    self.window = window

    final class EmptyContainer: EmptyDependency {}
    final class Dependency: RootDependency, RootBuilders {
      let agendaBuilder: AgendaBuildable = AgendaBuilder(dependency: EmptyContainer())
      let mapBuilder: MapBuildable = MapBuilder(dependency: EmptyContainer())
      let moreBuilder: MoreBuildable = MoreBuilder(dependency: EmptyContainer())
      let scheduleBuilder: ScheduleBuildable = ScheduleBuilder(dependency: EmptyContainer())
    }
    let rootBuilder = RootBuilder(dependency: Dependency())
    let rootRouter = rootBuilder.build()
    self.rootRouter = rootRouter
    rootRouter.launch(from: window)

    return true
  }

  private func didChangePendingNetworkRequests() {
    #if !targetEnvironment(macCatalyst)
    UIApplication.shared.isNetworkActivityIndicatorVisible = pendingNetworkRequests > 0
    #endif
  }

  func makeErrorViewController() -> ErrorViewController {
    let errorViewController = ErrorViewController()
    errorViewController.showsAppStoreButton = true
    errorViewController.delegate = self
    return errorViewController
  }
}

extension AppDelegate: ErrorViewControllerDelegate {
  func errorViewControllerDidTapAppStore(_: ErrorViewController) {
    if let url = URL.fosdemAppStore {
      UIApplication.shared.open(url)
    }
  }
}

private extension URL {
  static var fosdemAppStore: URL? {
    URL(string: "https://itunes.apple.com/it/app/id1513719757")
  }
}
