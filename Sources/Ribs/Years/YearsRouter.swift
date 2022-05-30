import RIBs

protocol YearsViewControllable: ViewControllable {
  func showYear(_ yearViewControllable: ViewControllable)
}

protocol YearsInteractable: Interactable, YearListener {}

final class YearsRouter: ViewableRouter<YearsInteractable, YearsViewControllable> {
  private var yearRouter: ViewableRouting?

  private let yearBuilder: YearBuildable

  init(interactor: YearsInteractable, viewController: YearsViewControllable, yearBuilder: YearBuildable) {
    self.yearBuilder = yearBuilder
    super.init(interactor: interactor, viewController: viewController)
  }
}

extension YearsRouter: YearsRouting {
  func routeToYear(_ year: Year) {
    if let yearRouter = yearRouter {
      detachChild(yearRouter)
      self.yearRouter = nil
    }

    let yearRouter = yearBuilder.build(with: .init(year: year), listener: interactor)
    self.yearRouter = yearRouter
    attachChild(yearRouter)
    viewController.showYear(yearRouter.viewControllable)
  }
}
