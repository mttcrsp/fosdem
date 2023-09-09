import Foundation

struct LaunchService {
  enum Error: CustomNSError {
    case versionDetectionFailed
  }

  var didLaunchAfterUpdate: () -> Bool
  var didLaunchAfterInstall: () -> Bool
  var didLaunchAfterFosdemYearChange: () -> Bool
  var detectStatus: () throws -> Void
  #if DEBUG
  var markAsLaunched: () -> Void
  #endif
}

extension LaunchService {
  static let latestFosdemYearKey = "LATEST_FOSDEM_YEAR"
  static let latestBundleShortVersionKey = "LATEST_BUNDLE_SHORT_VERSION"

  init(fosdemYear: Year = 2023, bundle: LaunchServiceBundle = Bundle.main, defaults: LaunchServiceDefaults = UserDefaults.standard) {
    var didLaunchAfterUpdate = false
    var didLaunchAfterInstall = false
    var didLaunchAfterFosdemYearChange = false
    self.didLaunchAfterUpdate = { didLaunchAfterUpdate }
    self.didLaunchAfterInstall = { didLaunchAfterInstall }
    self.didLaunchAfterFosdemYearChange = { didLaunchAfterFosdemYearChange }

    detectStatus = {
      guard let bundleShortVersion = bundle.bundleShortVersion else {
        throw Error.versionDetectionFailed
      }

      switch defaults.latestBundleShortVersion {
      case .some(bundleShortVersion):
        didLaunchAfterUpdate = false
        didLaunchAfterInstall = false
      case .some:
        didLaunchAfterUpdate = true
        didLaunchAfterInstall = false
      case nil:
        didLaunchAfterUpdate = false
        didLaunchAfterInstall = true
      }

      didLaunchAfterFosdemYearChange = !didLaunchAfterInstall && defaults.latestFosdemYear != fosdemYear

      defaults.latestFosdemYear = fosdemYear
      defaults.latestBundleShortVersion = bundleShortVersion
    }

    #if DEBUG
    markAsLaunched = {
      defaults.latestFosdemYear = fosdemYear
      defaults.latestBundleShortVersion = bundle.bundleShortVersion
    }
    #endif
  }
}

extension LaunchServiceDefaults {
  var latestFosdemYear: Int? {
    get { string(forKey: LaunchService.latestFosdemYearKey).flatMap { string in Int(string) } }
    set { set(newValue?.description, forKey: LaunchService.latestFosdemYearKey) }
  }

  var latestBundleShortVersion: String? {
    get { string(forKey: LaunchService.latestBundleShortVersionKey) }
    set { set(newValue, forKey: LaunchService.latestBundleShortVersionKey) }
  }
}

/// @mockable
protocol LaunchServiceProtocol {
  var didLaunchAfterUpdate: () -> Bool { get }
  var didLaunchAfterInstall: () -> Bool { get }
  var didLaunchAfterFosdemYearChange: () -> Bool { get }

  var detectStatus: () throws -> Void { get }
  #if DEBUG
  var markAsLaunched: () -> Void { get }
  #endif
}

extension LaunchService: LaunchServiceProtocol {}

protocol LaunchServiceBundle {
  var bundleShortVersion: String? { get }
}

extension Bundle: LaunchServiceBundle {}

protocol LaunchServiceDefaults: AnyObject {
  func string(forKey key: String) -> String?
  func set(_ value: Any?, forKey defaultName: String)
}

extension UserDefaults: LaunchServiceDefaults {}

protocol HasLaunchService {
  var launchService: LaunchServiceProtocol { get }
}
