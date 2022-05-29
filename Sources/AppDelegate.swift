import AVFAudio
import AVFoundation
import CoreLocation
import RIBs
import UIKit

extension Services: HasAgendaBuilder {
  var agendaBuilder: AgendaBuildable {
    AgendaBuilder(dependency: self)
  }
}

extension Services: HasMapBuilder {
  var mapBuilder: MapBuildable {
    MapBuilder(dependency: self)
  }
}

extension Services: HasScheduleBuilder {
  var scheduleBuilder: ScheduleBuildable {
    ScheduleBuilder(dependency: self)
  }
}

extension Services: HasMoreBuilder {
  var moreBuilder: MoreBuildable {
    MoreBuilder(dependency: self)
  }
}

extension Services: HasVideosBuilder {
  var videosBuilder: VideosBuildable {
    VideosBuilder(dependency: self)
  }
}

extension Services: HasEventBuilder {
  var eventBuilder: EventBuildable {
    EventBuilder(dependency: self)
  }
}

extension Services: HasAudioSession {
  var audioSession: AVAudioSessionProtocol {
    AVAudioSession.sharedInstance()
  }
}

extension Services: HasYearsBuilder {
  var yearsBuilder: YearsBuildable {
    YearsBuilder(dependency: self)
  }
}

extension Services: HasYearBuilder {
  var yearBuilder: YearBuildable {
    YearBuilder(dependency: self)
  }
}

extension Services: HasPlayer {
  static let _player = AVPlayer()

  var player: AVPlayerProtocol {
    Services._player
  }
}

extension Services: HasNotificationCenter {
  var notificationCenter: NotificationCenter {
    .default
  }
}

extension Services: HasLocationService {
  static let _locationService = LocationService()

  var locationService: LocationServiceProtocol {
    Services._locationService
  }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  private var pendingNetworkRequests = 0 {
    didSet { didChangePendingNetworkRequests() }
  }

  private var rootRouter: LaunchRouting?

  func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
//    let rootViewController: UIViewController
//    do {
//      rootViewController = ApplicationController(dependencies: try makeServices())
//    } catch {
//      rootViewController = makeErrorViewController()
//    }
//
//    let window = UIWindow()
//    window.tintColor = .fos_label
//    window.rootViewController = rootViewController
//    window.makeKeyAndVisible()
//    self.window = window

    let window = UIWindow()
    window.tintColor = .fos_label
    self.window = window

    do {
      let services = try makeServices()
      let rootBuilder = RootBuilder(dependency: services)
      let rootRouter = rootBuilder.build()
      self.rootRouter = rootRouter
      rootRouter.launch(from: window)
    } catch {
      print(error)
    }

    return true
  }

  private func didChangePendingNetworkRequests() {
    #if !targetEnvironment(macCatalyst)
    UIApplication.shared.isNetworkActivityIndicatorVisible = pendingNetworkRequests > 0
    #endif
  }

  private func makeServices() throws -> Services {
    #if DEBUG
    let services = try DebugServices()
    #else
    let services = try Services()
    #endif
    services.networkService.delegate = self
    return services
  }

  func makeErrorViewController() -> ErrorViewController {
    let errorViewController = ErrorViewController()
    errorViewController.showsAppStoreButton = true
    errorViewController.delegate = self
    return errorViewController
  }
}

extension AppDelegate: NetworkServiceDelegate {
  func networkServiceDidBeginRequest(_: NetworkService) {
    OperationQueue.main.addOperation { [weak self] in
      self?.pendingNetworkRequests += 1
    }
  }

  func networkServiceDidEndRequest(_: NetworkService) {
    OperationQueue.main.addOperation { [weak self] in
      self?.pendingNetworkRequests -= 1
    }
  }
}

extension AppDelegate: ErrorViewControllerDelegate {
  func errorViewControllerDidTapAppStore(_: ErrorViewController) {
    if let url = URL.fosdemAppStore {
      UIApplication.shared.open(url)
    }
  }
}
