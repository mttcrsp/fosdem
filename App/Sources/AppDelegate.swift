import UIKit

//    let parser = Parser()
//
//    for track in try! persistenceService.performReadSync(GetAllTracks()) {
//      for event in try! persistenceService.performReadSync(GetEventsByTrack(track: track.name)) {
//        if let abstract = event.abstract {
//          if let node = parser.parse(abstract) {
//            dump(node)
//          } else {
//            print("parsing failed for event \(event.id)")
//          }
//        }
//      }
//    }

class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  private var applicationController: ApplicationController? {
    window?.rootViewController as? ApplicationController
  }

  func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    let rootViewController: UIViewController
    do {
      #if DEBUG
      let services = try DebugServices()
      #else
      let services = try Services()
      #endif
      rootViewController = ApplicationController(dependencies: services)
//      rootViewController = AbstractsComparisonController(dependencies: services)
//      rootViewController = FontSampleViewController()
    } catch {
      let errorViewController = ErrorViewController()
      errorViewController.showsAppStoreButton = true
      errorViewController.delegate = self
      rootViewController = errorViewController
    }

    let window = UIWindow()
    window.tintColor = .label
    window.rootViewController = rootViewController
    window.makeKeyAndVisible()
    self.window = window

    return true
  }

  func applicationDidBecomeActive(_: UIApplication) {
    applicationController?.applicationDidBecomeActive()
  }

  func applicationWillResignActive(_: UIApplication) {
    applicationController?.applicationWillResignActive()
  }
}

extension AppDelegate: ErrorViewControllerDelegate {
  func errorViewControllerDidTapAppStore(_: ErrorViewController) {
    if let url = URL.fosdemAppStore {
      UIApplication.shared.open(url)
    }
  }
}
