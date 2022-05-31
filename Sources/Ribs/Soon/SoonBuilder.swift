import RIBs

typealias SoonBuilders = HasEventBuilder
typealias SoonServices = HasFavoritesService & HasSoonService
typealias SoonDependency = SoonBuilders & SoonServices

protocol SoonBuildable: Buildable {
  func build(withListener listener: SoonListener) -> SoonRouting
}

final class SoonBuilder: Builder<SoonDependency>, SoonBuildable {
  func build(withListener listener: SoonListener) -> SoonRouting {
    let viewController = SoonViewController()
    let interactor = SoonInteractor(services: dependency, presenter: viewController)
    let router = SoonRouter(builders: dependency, interactor: interactor, viewController: viewController)
    interactor.listener = listener
    interactor.router = router
    viewController.listener = interactor
    return router
  }
}
