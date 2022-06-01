import RIBs

protocol MoreBuilders {
  var yearsBuilder: YearsBuildable { get }
  var videosBuilder: VideosBuildable { get }
}

protocol MoreServices {
  var acknowledgementsService: AcknowledgementsServiceProtocol { get }
  var infoService: InfoServiceProtocol { get }
  var openService: OpenServiceProtocol { get }
  var timeService: TimeServiceProtocol { get }
  var yearsService: YearsServiceProtocol { get }
}

protocol MoreDependency: Dependency, MoreBuilders, MoreServices {}

protocol MoreBuildable: Buildable {
  func build() -> MoreRouting
}

final class MoreBuilder: Builder<MoreDependency>, MoreBuildable {
  func build() -> MoreRouting {
    let viewController = MoreRootViewController()
    let interactor = MoreInteractor(presenter: viewController, services: dependency)
    let router = MoreRouter(builders: dependency, interactor: interactor, viewController: viewController)
    viewController.listener = interactor
    interactor.router = router
    return router
  }
}
