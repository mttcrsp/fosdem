import NeedleFoundation
import RIBs

struct YearArguments {
  let year: Year
}

protocol YearDependency: NeedleFoundation.Dependency {
  var yearsService: YearsServiceProtocol { get }
}

final class YearComponent: NeedleFoundation.Component<YearDependency> {
  var eventBuilder: EventBuildable { fatalError() }
  var searchBuilder: SearchBuildable { fatalError() }
}

protocol YearBuildable: Buildable {
  func finalStageBuild(withDynamicDependency dynamicDependency: (YearArguments, YearListener)) -> YearRouting
}

final class YearBuilder: MultiStageComponentizedBuilder<YearComponent, YearRouting, (YearArguments, YearListener)>, YearBuildable {
  override func finalStageBuild(with component: YearComponent, _ dynamicDependency: (arguments: YearArguments, listener: YearListener)) -> YearRouting {
    let viewController = YearViewController()
    let interactor = YearInteractor(arguments: dynamicDependency.arguments, component: component, presenter: viewController)
    let router = YearRouter(component: component, interactor: interactor, viewController: viewController)
    interactor.listener = dynamicDependency.listener
    interactor.router = router
    viewController.listener = interactor
    return router
  }
}
