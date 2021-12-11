import Foundation

final class LaunchService {
  enum Error: CustomNSError {
    case versionDetectionFailed
  }

  static let latestFosdemYearKey = "LATEST_FOSDEM_YEAR"
  static let latestBundleShortVersionKey = "LATEST_BUNDLE_SHORT_VERSION"

  private(set) var didLaunchAfterUpdate = false
  private(set) var didLaunchAfterInstall = false
  private(set) var didLaunchAfterFosdemYearChange = false

  private let fosdemYear: Int
  private let bundle: LaunchServiceBundle
  private let defaults: LaunchServiceDefaults

  init(fosdemYear: Int, bundle: LaunchServiceBundle = Bundle.main, defaults: LaunchServiceDefaults = UserDefaults.standard) {
    self.bundle = bundle
    self.defaults = defaults
    self.fosdemYear = fosdemYear
  }

  func detectStatus() throws {
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
  func markAsLaunched() {
    defaults.latestFosdemYear = fosdemYear
    defaults.latestBundleShortVersion = bundle.bundleShortVersion
  }
  #endif
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
  var didLaunchAfterUpdate: Bool { get }
  var didLaunchAfterInstall: Bool { get }
  var didLaunchAfterFosdemYearChange: Bool { get }

  func detectStatus() throws
  #if DEBUG
  func markAsLaunched()
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
