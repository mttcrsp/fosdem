import RIBs
import UIKit

typealias AgendaBuilders = HasEventBuilder & HasSoonBuilder
typealias AgendaServices = HasFavoritesService & HasPersistenceService & HasTimeService
typealias AgendaDependency = AgendaBuilders & AgendaServices

protocol AgendaBuildable {
  func build(withListener listener: AgendaListener) -> ViewableRouting
}

final class AgendaBuilder: Builder<AgendaDependency>, AgendaBuildable {
  func build(withListener listener: AgendaListener) -> ViewableRouting {
    let viewController = AgendaViewController()
    let interactor = AgendaInteractor(presenter: viewController, services: dependency)
    let router = AgendaRouter(builders: dependency, interactor: interactor, viewController: viewController)
    interactor.router = router
    interactor.listener = listener
    viewController.listener = interactor
    return router
  }
}
