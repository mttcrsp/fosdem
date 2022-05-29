import RIBs

typealias MapDependency = HasBuildingsService
  & HasLocationService
  & HasNotificationCenter
  & HasOpenService

protocol MapBuildable: Buildable {
  func build(with listener: MapListener) -> ViewableRouting
}

class MapBuilder: Builder<MapDependency>, MapBuildable {
  func build(with listener: MapListener) -> ViewableRouting {
    let viewController = MapContainerViewController()
    let interactor = MapInteractor(dependency: dependency, presenter: viewController)
    let router = ViewableRouter(interactor: interactor, viewController: viewController)
    interactor.listener = listener
    return router
  }
}
