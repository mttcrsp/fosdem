import Foundation
import RIBs

protocol MapServices {
  var buildingsService: BuildingsServiceProtocol { get }
  var locationService: LocationServiceProtocol { get }
  var notificationCenter: NotificationCenter { get }
  var openService: OpenServiceProtocol { get }
}

protocol MapDependency: Dependency, MapServices {}

protocol MapBuildable: Buildable {
  func build(withDynamicDependency dependency: MapDependency, listener: MapListener) -> ViewableRouting
}

class MapBuilder: Builder<EmptyDependency>, MapBuildable {
  func build(withDynamicDependency dependency: MapDependency, listener: MapListener) -> ViewableRouting {
    let viewController = MapRootViewController()
    let interactor = MapInteractor(presenter: viewController, services: dependency)
    let router = ViewableRouter(interactor: interactor, viewController: viewController)
    interactor.listener = listener
    return router
  }
}
