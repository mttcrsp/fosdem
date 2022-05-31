import RIBs

typealias YearsDependency = HasYearBuilder & HasYearsService

protocol YearsBuildable: Buildable {
  func build(withListener listener: YearsListener) -> YearsRouting
}

final class YearsBuilder: Builder<YearsDependency>, YearsBuildable {
  func build(withListener listener: YearsListener) -> YearsRouting {
    let viewController = YearsRootViewController()
    let interactor = YearsInteractor(presenter: viewController, dependency: dependency)
    let router = YearsRouter(interactor: interactor, viewController: viewController, yearBuilder: dependency.yearBuilder)
    interactor.router = router
    interactor.listener = listener
    viewController.listener = interactor
    return router
  }
}
