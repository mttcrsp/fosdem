import AVFAudio
import AVFoundation
import CoreLocation
import RIBs
import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  private var rootRouter: LaunchRouting?

  func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    let window = UIWindow()
    window.tintColor = .fos_label
    self.window = window

    final class EmptyContainer: EmptyDependency {}
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
