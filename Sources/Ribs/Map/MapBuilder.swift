import Foundation
import NeedleFoundation
import RIBs

protocol MapDependency: NeedleFoundation.Dependency {}

final class MapComponent: NeedleFoundation.Component<MapDependency> {
  lazy var buildingsService: BuildingsServiceProtocol =
    BuildingsService(bundleService: bundleService)

  lazy var bundleService: BundleServiceProtocol =
    BundleService()

  lazy var locationService: LocationServiceProtocol =
    LocationService()

  lazy var openService: OpenServiceProtocol =
    OpenService()
}

protocol MapBuildable: Buildable {
  func finalStageBuild(with component: MapComponent, _ listener: MapListener) -> ViewableRouting
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
