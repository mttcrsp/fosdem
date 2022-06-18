import RIBs
import UIKit

protocol AgendaBuilders {
  var eventBuilder: EventBuildable { get }
  var soonBuilder: SoonBuildable { get }
}

protocol AgendaServices {
  var favoritesService: FavoritesServiceProtocol { get }
  var persistenceService: PersistenceServiceProtocol { get }
  var timeService: TimeServiceProtocol { get }
}

protocol AgendaDependency: Dependency, AgendaBuilders, AgendaServices {}

protocol AgendaBuildable {
  func build(withDynamicDependency dependency: AgendaDependency, listener: AgendaListener) -> ViewableRouting
}

final class AgendaBuilder: Builder<EmptyDependency>, AgendaBuildable {
  func build(withDynamicDependency dependency: AgendaDependency, listener: AgendaListener) -> ViewableRouting {
    let viewController = AgendaViewController()
    let interactor = AgendaInteractor(presenter: viewController, services: dependency)
    let router = AgendaRouter(builders: dependency, interactor: interactor, viewController: viewController)
    interactor.router = router
    interactor.listener = listener
    viewController.listener = interactor
    return router
  }
}
