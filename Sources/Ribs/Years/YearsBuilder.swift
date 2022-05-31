import RIBs

typealias YearsBuilders = HasYearBuilder
typealias YearsServices = HasYearsService
typealias YearsDependency = YearsBuilders & YearsServices

protocol YearsBuildable: Buildable {
  func build(withListener listener: YearsListener) -> YearsRouting
}

final class YearsBuilder: Builder<YearsDependency>, YearsBuildable {
  func build(withListener listener: YearsListener) -> YearsRouting {
    let viewController = YearsRootViewController()
    let interactor = YearsInteractor(presenter: viewController, services: dependency)
    let router = YearsRouter(builders: dependency, interactor: interactor, viewController: viewController)
    interactor.router = router
    interactor.listener = listener
    viewController.listener = interactor
    return router
  }
}
