import Foundation

struct LaunchClient {
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

extension LaunchClient {
  static let latestFosdemYearKey = "LATEST_FOSDEM_YEAR"
  static let latestBundleShortVersionKey = "LATEST_BUNDLE_SHORT_VERSION"

  init(fosdemYear: Year = 2023, bundle: LaunchClientBundle = Bundle.main, defaults: LaunchClientDefaults = UserDefaults.standard) {
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

extension LaunchClientDefaults {
  var latestFosdemYear: Int? {
    get { string(forKey: LaunchClient.latestFosdemYearKey).flatMap { string in Int(string) } }
    set { set(newValue?.description, forKey: LaunchClient.latestFosdemYearKey) }
  }

  var latestBundleShortVersion: String? {
    get { string(forKey: LaunchClient.latestBundleShortVersionKey) }
    set { set(newValue, forKey: LaunchClient.latestBundleShortVersionKey) }
  }
}

/// @mockable
protocol LaunchClientProtocol {
  var didLaunchAfterUpdate: () -> Bool { get }
  var didLaunchAfterInstall: () -> Bool { get }
  var didLaunchAfterFosdemYearChange: () -> Bool { get }

  var detectStatus: () throws -> Void { get }
  #if DEBUG
  var markAsLaunched: () -> Void { get }
  #endif
}

extension LaunchClient: LaunchClientProtocol {}

protocol LaunchClientBundle {
  var bundleShortVersion: String? { get }
}

extension Bundle: LaunchClientBundle {}

protocol LaunchClientDefaults: AnyObject {
  func string(forKey key: String) -> String?
  func set(_ value: Any?, forKey defaultName: String)
}

extension UserDefaults: LaunchClientDefaults {}
