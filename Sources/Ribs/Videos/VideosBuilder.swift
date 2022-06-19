import NeedleFoundation
import RIBs

protocol VideosDependency: NeedleFoundation.Dependency {
  var persistenceService: PersistenceServiceProtocol { get }
  var playbackService: PlaybackServiceProtocol { get }
}

final class VideosComponent: NeedleFoundation.Component<VideosDependency> {
  var videosService: VideosServiceProtocol {
    shared { VideosService(playbackService: dependency.playbackService, persistenceService: dependency.persistenceService) }
  }
}

extension VideosComponent {
  func buildEventRouter(withArguments arguments: EventArguments) -> ViewableRouting {
    EventBuilder(componentBuilder: { EventComponent(parent: self) })
      .finalStageBuild(withDynamicDependency: arguments)
  }
}

protocol VideosBuildable: Buildable {
  func finalStageBuild(withDynamicDependency dynamicDependency: VideosListener) -> VideosRouting
}

final class VideosBuilder: MultiStageComponentizedBuilder<VideosComponent, VideosRouting, VideosListener>, VideosBuildable {
  override func finalStageBuild(with component: VideosComponent, _ listener: VideosListener) -> VideosRouting {
    let viewController = VideosViewController()
    let interactor = VideosInteractor(component: component, presenter: viewController)
    let router = VideosRouter(component: component, interactor: interactor, viewController: viewController)
    interactor.listener = listener
    interactor.router = router
    viewController.listener = interactor
    return router
  }
}
