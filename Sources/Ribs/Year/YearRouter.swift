import RIBs

protocol YearViewControllable: ViewControllable {
  func addSearch(_ searchViewControllable: ViewControllable)
  func showEvent(_ eventViewControllable: ViewControllable)
  func showSearchResult(_ eventViewController: ViewControllable)
}

protocol YearInteractable: Interactable, SearchListener {}

final class YearRouter: ViewableRouter<YearInteractable, YearViewControllable> {
  private var eventRouter: ViewableRouting?
  private var searchResultRouter: ViewableRouting?

  private let builders: YearBuilders

  init(builders: YearBuilders, interactor: YearInteractable, viewController: YearViewControllable) {
    self.builders = builders
    super.init(interactor: interactor, viewController: viewController)
  }

  override func didLoad() {
    super.didLoad()

    let searchRouter = builders.searchBuilder.build(withListener: interactor)
    attachChild(searchRouter)
    viewController.addSearch(searchRouter.viewControllable)
  }
}

extension YearRouter: YearRouting {
  func routeToEvent(_ event: Event) {
    if let eventRouter = eventRouter {
      detachChild(eventRouter)
      self.eventRouter = nil
    }

    let eventRouter = makeEventRouter(for: event)
    self.eventRouter = eventRouter
    attachChild(eventRouter)
    viewController.showEvent(eventRouter.viewControllable)
  }

  func routeToSearchResult(_ event: Event) {
    if let searchResultRouter = searchResultRouter {
      detachChild(searchResultRouter)
      self.searchResultRouter = nil
    }

    let searchResultRouter = makeEventRouter(for: event)
    self.searchResultRouter = searchResultRouter
    attachChild(searchResultRouter)
    viewController.showSearchResult(searchResultRouter.viewControllable)
  }
}

private extension YearRouter {
  func makeEventRouter(for event: Event) -> ViewableRouting {
    builders.eventBuilder.build(with: .init(event: event, allowsFavoriting: false))
  }
}
