import NeedleFoundation
import RIBs

protocol AgendaDependency: NeedleFoundation.Dependency {
  var favoritesService: FavoritesServiceProtocol { get }
  var timeService: TimeServiceProtocol { get }
}

final class AgendaComponent: NeedleFoundation.Component<AgendaDependency> {
  let persistenceService: PersistenceServiceProtocol

  init(parent: Scope, persistenceService: PersistenceServiceProtocol) {
    self.persistenceService = persistenceService
    super.init(parent: parent)
  }

  var eventBuilder: EventBuildable {
    EventBuilder(componentBuilder: { EventComponent(parent: self) })
  }

  var soonBuilder: SoonBuildable {
    SoonBuilder(componentBuilder: { SoonComponent(parent: self) })
  }
}

protocol AgendaBuildable {
  func build(withListener listener: AgendaListener) -> ViewableRouting
}

final class AgendaBuilder: MultiStageComponentizedBuilder<AgendaComponent, ViewableRouting, AgendaListener>, AgendaBuildable {
  override func finalStageBuild(with component: AgendaComponent, _ listener: AgendaListener) -> ViewableRouting {
    let viewController = AgendaViewController()
    let interactor = AgendaInteractor(component: component, presenter: viewController)
    let router = AgendaRouter(component: component, interactor: interactor, viewController: viewController)
    interactor.router = router
    interactor.listener = listener
    viewController.listener = interactor
    return router
  }
  
  func build(withListener listener: AgendaListener) -> ViewableRouting {
    finalStageBuild(withDynamicDependency: listener)
  }
}
