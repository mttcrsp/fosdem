import Foundation
import RIBs

struct EventArguments {
  let event: Event
  let allowsFavoriting: Bool

  init(event: Event, allowsFavoriting: Bool = true) {
    self.event = event
    self.allowsFavoriting = allowsFavoriting
  }
}

protocol EventServices {
  var player: AVPlayerProtocol { get }
  var audioSession: AVAudioSessionProtocol { get }
  var favoritesService: FavoritesServiceProtocol { get }
  var notificationCenter: NotificationCenter { get }
  var playbackService: PlaybackServiceProtocol { get }
  var timeService: TimeServiceProtocol { get }
}

protocol EventDependency: Dependency, EventServices {}

protocol EventBuildable {
  func build(with arguments: EventArguments) -> ViewableRouting
}

final class EventBuilder: Builder<EventDependency>, EventBuildable {
  func build(with arguments: EventArguments) -> ViewableRouting {
    let viewController = EventRootViewController(event: arguments.event)
    let interactor = EventInteractor(arguments: arguments, presenter: viewController, services: dependency)
    let router = ViewableRouter(interactor: interactor, viewController: viewController)
    viewController.listener = interactor
    return router
  }
}
