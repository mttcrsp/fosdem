import NeedleFoundation
import RIBs
import UIKit

final class EmptyComponent: NeedleFoundation.EmptyDependency {}

protocol RootDependency: NeedleFoundation.Dependency {}

final class RootComponent: BootstrapComponent {
  lazy var openService: OpenServiceProtocol =
    OpenService()
}

extension RootComponent: MapDependency {
  func buildMapRouter(withListener listener: MapListener) -> ViewableRouting {
    MapBuilder(componentBuilder: { MapComponent(parent: self) })
      .finalStageBuild(withDynamicDependency: listener)
  }
}

extension RootComponent {
  private final class EmptyRibsComponent: RIBs.EmptyDependency {}

  var agendaBuilder: AgendaBuildable {
    AgendaBuilder(dependency: EmptyRibsComponent())
  }

  var moreBuilder: MoreBuildable {
    MoreBuilder(dependency: EmptyRibsComponent())
  }

  var scheduleBuilder: ScheduleBuildable {
    ScheduleBuilder(dependency: EmptyRibsComponent())
  }
}

protocol RootBuildable: Buildable {
  func build(with component: RootComponent) -> LaunchRouting
}

class RootBuilder: SimpleComponentizedBuilder<RootComponent, LaunchRouting> {
  override func build(with component: RootComponent) -> LaunchRouting {
    let viewController = RootViewController()
    let interactor = RootInteractor(presenter: viewController, component: component)
    let router = RootRouter(component: component, interactor: interactor, viewController: viewController)
    interactor.router = router
    viewController.listener = interactor
    return router
  }
}
