import NeedleFoundation
import RIBs

protocol MoreDependency: NeedleFoundation.Dependency {
  var acknowledgementsService: AcknowledgementsServiceProtocol { get }
  var infoService: InfoServiceProtocol { get }
  var openService: OpenServiceProtocol { get }
  var timeService: TimeServiceProtocol { get }
  var yearsService: YearsServiceProtocol { get }
}

final class MoreComponent: NeedleFoundation.Component<MoreDependency> {
  var yearsBuilder: YearsBuildable { fatalError() }
  var videosBuilder: VideosBuildable { fatalError() }
}

protocol MoreBuildable: Buildable {
  func build() -> ViewableRouting
}

final class MoreBuilder: SimpleComponentizedBuilder<MoreComponent, ViewableRouting>, MoreBuildable {
  override func build(with component: MoreComponent) -> ViewableRouting {
    let viewController = MoreRootViewController()
    let interactor = MoreInteractor(component: component, presenter: viewController)
    let router = MoreRouter(component: component, interactor: interactor, viewController: viewController)
    viewController.listener = interactor
    interactor.router = router
    return router
  }
}
