import NeedleFoundation
import RIBs
import UIKit

final class RootComponent: BootstrapComponent {}

extension RootComponent {
  var notificationCenter: NotificationCenter {
    shared { .default }
  }
}

extension RootComponent {
  var bundleService: BundleService {
    shared { .init() }
  }

  var openService: OpenServiceProtocol {
    shared { OpenService() }
  }
}

extension RootComponent: _MapDependency {
  var mapComponent: MapComponent {
    MapComponent(parent: self)
  }
}

protocol _MapDependency: NeedleFoundation.Dependency {
  var notificationCenter: NotificationCenter { get }
  var bundleService: BundleService { get }
  var openService: OpenServiceProtocol { get }
}

final class MapComponent: NeedleFoundation.Component<_MapDependency> {
  lazy var buildingsService: BuildingsServiceProtocol =
    BuildingsService(bundleService: dependency.bundleService)
}

// extension MapComponent {
//  var mapBuilder: MapBuildable {
//    MapBuilder(dependency: EmptyComponent())
//  }
// }

final class EmptyComponent: NeedleFoundation.EmptyDependency {}

class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  private var rootRouter: LaunchRouting?

  func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    registerProviderFactories()

    let window = UIWindow()
    window.tintColor = .fos_label
    self.window = window

    final class EmptyContainer: RIBs.EmptyDependency {}
    final class Dependency: RootDependency, RootBuilders {
      let openService: OpenServiceProtocol = OpenService()
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
}
