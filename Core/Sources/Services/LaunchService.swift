import Foundation

protocol LaunchServiceBundle {
  var bundleShortVersion: String? { get }
}

protocol LaunchServiceDefaults: AnyObject {
  func string(forKey key: String) -> String?
  func set(_ value: Any?, forKey defaultName: String)
}

final class LaunchService {
  enum Error: CustomNSError {
    case versionDetectionFailed
  }

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
    get { string(forKey: .latestFosdemYearKey).flatMap { string in Int(string) } }
    set { set(newValue?.description, forKey: .latestFosdemYearKey) }
  }

  var latestBundleShortVersion: String? {
    get { string(forKey: .latestBundleShortVersionKey) }
    set { set(newValue, forKey: .latestBundleShortVersionKey) }
  }
}

private extension String {
  static var latestFosdemYearKey: String { "LATEST_FOSDEM_YEAR" }
  static var latestBundleShortVersionKey: String { "LATEST_BUNDLE_SHORT_VERSION" }
}

extension Bundle: LaunchServiceBundle {}

extension UserDefaults: LaunchServiceDefaults {}
