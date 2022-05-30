import RIBs
import UIKit

protocol AgendaListener: AnyObject {
  func agendaDidError(_ error: Error)
}

typealias AgendaDependency =
  HasEventBuilder &
  HasFavoritesService &
  HasPersistenceService &
  HasTimeService &
  HasSoonBuilder

protocol AgendaBuildable {
  func build(withListener listener: AgendaListener) -> ViewableRouting
}

final class AgendaBuilder: Builder<AgendaDependency>, AgendaBuildable {
  func build(withListener listener: AgendaListener) -> ViewableRouting {
    let viewController = AgendaViewController()
    let interactor = AgendaInteractor(dependency: dependency, presenter: viewController)
    let router = AgendaRouter(
      interactor: interactor,
      viewController: viewController,
      eventBuilder: dependency.eventBuilder,
      soonBuilder: dependency.soonBuilder
    )

    interactor.router = router
    interactor.listener = listener
    viewController.listener = interactor
    return router
  }
}
