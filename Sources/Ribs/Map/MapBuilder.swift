import Foundation
import NeedleFoundation
import RIBs

protocol MapDependency: NeedleFoundation.Dependency {
  var buildingsService: BuildingsServiceProtocol { get }
  var bundleService: BundleServiceProtocol { get }
  var locationService: LocationServiceProtocol { get }
  var openService: OpenServiceProtocol { get }
}

final class MapComponent: NeedleFoundation.Component<MapDependency> {}

protocol MapBuildable: Buildable {
  func finalStageBuild(withDynamicDependency dynamicDependency: MapListener) -> ViewableRouting
}

class MapBuilder: MultiStageComponentizedBuilder<MapComponent, ViewableRouting, MapListener>, MapBuildable {
  override func finalStageBuild(with component: MapComponent, _ listener: MapListener) -> ViewableRouting {
    let viewController = MapRootViewController()
    let interactor = MapInteractor(presenter: viewController, component: component)
    let router = ViewableRouter(interactor: interactor, viewController: viewController)
    interactor.listener = listener
    viewController.listener = interactor
    return router
  }
}
