import RIBs

protocol YearsViewControllable: ViewControllable {
  func showYear(_ yearViewControllable: ViewControllable)
}

protocol YearsInteractable: Interactable, YearListener {}

final class YearsRouter: ViewableRouter<YearsInteractable, YearsViewControllable> {
  private var yearRouter: ViewableRouting?

  private let component: YearsComponent

  init(component: YearsComponent, interactor: YearsInteractable, viewController: YearsViewControllable) {
    self.component = component
    super.init(interactor: interactor, viewController: viewController)
  }
}

extension YearsRouter: YearsRouting {
  func routeToYear(_ year: Year) {
    if let yearRouter = yearRouter {
      detachChild(yearRouter)
      self.yearRouter = nil
    }

    let yearRouter = component.yearBuilder.build(with: .init(year: year), listener: interactor)
    self.yearRouter = yearRouter
    attachChild(yearRouter)
    viewController.showYear(yearRouter.viewControllable)
  }
}
