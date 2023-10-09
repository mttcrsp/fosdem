import Dependencies
import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  @Dependency(\.favoritesClient) var favoritesClient
  @Dependency(\.launchClient) var launchClient
  @Dependency(\.persistenceClient) var persistenceClient
  @Dependency(\.preloadClient) var preloadClient

  private var applicationController: ApplicationController? {
    window?.rootViewController as? ApplicationController
  }

  func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    let rootViewController: UIViewController
    do {
      try launchClient.detectStatus()
      // Remove the database after each update as the new database might contain
      // updates even if the year did not change.
      if launchClient.didLaunchAfterUpdate() {
        try preloadClient.removeDatabase()
      }
      // In the 2020 release, installs and updates where not being recorded. This
      // means that users updating from 2020 to new version will be registered as
      // new installs. The database also needs to be removed for those users too.
      if launchClient.didLaunchAfterInstall() {
        do {
          try preloadClient.removeDatabase()
        } catch {
          if let error = error as? CocoaError, error.code == .fileNoSuchFile {
            // Do nothing
          } else {
            throw error
          }
        }
      }

      try preloadClient.preloadDatabaseIfNeeded()
      try persistenceClient.load(try preloadClient.databasePath())

      if launchClient.didLaunchAfterFosdemYearChange() {
        favoritesClient.removeAllTracksAndEvents()
      }
      favoritesClient.migrate()

      rootViewController = ApplicationController()
    } catch {
      rootViewController = makeErrorViewController()
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

  func makeErrorViewController() -> ErrorViewController {
    let errorViewController = ErrorViewController()
    errorViewController.onAppStoreTap = {
      if let url = URL.fosdemAppStore {
        UIApplication.shared.open(url)
      }
    }
    return errorViewController
  }
}
