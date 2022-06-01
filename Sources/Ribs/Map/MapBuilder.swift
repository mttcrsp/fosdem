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
  func build(withListener listener: MapListener) -> ViewableRouting
}

class MapBuilder: Builder<MapDependency>, MapBuildable {
  func build(withListener listener: MapListener) -> ViewableRouting {
    let viewController = MapRootViewController()
    let interactor = MapInteractor(presenter: viewController, services: dependency)
    let router = ViewableRouter(interactor: interactor, viewController: viewController)
    interactor.listener = listener
    return router
  }
}
