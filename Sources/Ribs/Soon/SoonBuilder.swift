import NeedleFoundation
import RIBs

protocol SoonDependency: NeedleFoundation.Dependency {
  var timeService: TimeServiceProtocol { get }
  var favoritesService: FavoritesServiceProtocol { get }
  var persistenceService: PersistenceServiceProtocol { get }
}

final class SoonComponent: NeedleFoundation.Component<SoonDependency> {
  var soonService: SoonServiceProtocol {
    shared { SoonService(timeService: dependency.timeService, persistenceService: dependency.persistenceService) }
  }

  var eventBuilder: EventBuildable { fatalError() }
}

protocol SoonBuildable: Buildable {
  func finalStageBuild(withDynamicDependency dynamicDependency: SoonListener) -> SoonRouting
}

final class SoonBuilder: MultiStageComponentizedBuilder<SoonComponent, SoonRouting, SoonListener>, SoonBuildable {
  override func finalStageBuild(with component: SoonComponent, _ listener: SoonListener) -> SoonRouting {
    let viewController = SoonViewController()
    let interactor = SoonInteractor(component: component, presenter: viewController)
    let router = SoonRouter(component: component, interactor: interactor, viewController: viewController)
    interactor.listener = listener
    interactor.router = router
    viewController.listener = interactor
    return router
  }
}
