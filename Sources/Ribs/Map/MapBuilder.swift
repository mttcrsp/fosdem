import RIBs

typealias MapDependency = HasBuildingsService
  & HasLocationService
  & HasNotificationCenter
  & HasOpenService

protocol MapBuildable: Buildable {
  func build(withListener listener: MapListener) -> ViewableRouting
}

class MapBuilder: Builder<MapDependency>, MapBuildable {
  func build(withListener listener: MapListener) -> ViewableRouting {
    let viewController = MapRootViewController()
    let interactor = MapInteractor(dependency: dependency, presenter: viewController)
    let router = ViewableRouter(interactor: interactor, viewController: viewController)
    interactor.listener = listener
    return router
  }
}
