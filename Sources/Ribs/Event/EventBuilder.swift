import Foundation
import NeedleFoundation
import RIBs

struct EventArguments {
  let event: Event
  let allowsFavoriting: Bool

  init(event: Event, allowsFavoriting: Bool = true) {
    self.event = event
    self.allowsFavoriting = allowsFavoriting
  }
}

protocol EventDependency: NeedleFoundation.Dependency {
  var player: AVPlayerProtocol { get }
  var audioSession: AVAudioSessionProtocol { get }
  var favoritesService: FavoritesServiceProtocol { get }
  var notificationCenter: NotificationCenter { get }
  var playbackService: PlaybackServiceProtocol { get }
  var timeService: TimeServiceProtocol { get }
}

final class EventComponent: NeedleFoundation.Component<EventDependency> {}

protocol EventBuildable {
  func finalStageBuild(withDynamicDependency dynamicDependency: EventArguments) -> ViewableRouting
}

final class EventBuilder: MultiStageComponentizedBuilder<EventComponent, ViewableRouting, EventArguments>, EventBuildable {
  override func finalStageBuild(with component: EventComponent, _ arguments: EventArguments) -> ViewableRouting {
    let viewController = EventRootViewController(event: arguments.event)
    let interactor = EventInteractor(arguments: arguments, component: component, presenter: viewController)
    let router = ViewableRouter(interactor: interactor, viewController: viewController)
    viewController.listener = interactor
    return router
  }
}
