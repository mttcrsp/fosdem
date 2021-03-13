import ProjectDescription

enum Configuration {
  static let bundleID = "com.mttcrsp.fosdem"
  static let deploymentTarget = DeploymentTarget.iOS(targetVersion: "11.0", devices: [.iphone, .ipad])
}

extension Target {
  static func module(name: String, dependencies: [TargetDependency] = []) -> Target {
    Target(
      name: name,
      platform: .iOS,
      product: .staticFramework,
      bundleId: "\(Configuration.bundleID).\(name.lowercased())",
      deploymentTarget: Configuration.deploymentTarget,
      infoPlist: .default,
      sources: ["Modules/\(name)/**/*"],
      resources: ["Modules/\(name)/**/*"],
      dependencies: dependencies
    )
  }
}

let swiftFormat = TargetAction.post(
  script: "swiftformat .",
  name: "SwiftFormat"
)

let grdb = Package.remote(
  url: "https://github.com/mttcrsp/GRDB.swift",
  requirement: .branch("master")
)

let l10n = Target.module(name: "L10n")

let ui = Target.module(name: "UI", dependencies: [.target(name: l10n.name)])

let app = Target(
  name: "FOSDEM",
  platform: .iOS,
  product: .app,
  bundleId: Configuration.bundleID,
  deploymentTarget: Configuration.deploymentTarget,
  infoPlist: .extendingDefault(with: [
    "CFBundleVersion": "1",
    "CFBundleShortVersionString": "1.2.0",
    "UIBackgroundModes": .array(["audio"]),
    "ITSAppUsesNonExemptEncryption": .boolean(false),
    "UILaunchStoryboardName": .string("LaunchScreen"),
    "NSLocationWhenInUseUsageDescription": "The app uses your location data to display your current position within a map. Location data is never recorded and will never leave the app.",
    "UISupportedInterfaceOrientations~ipad": .array([
      "UIInterfaceOrientationPortrait",
      "UIInterfaceOrientationLandscapeLeft",
      "UIInterfaceOrientationLandscapeRight",
      "UIInterfaceOrientationPortraitUpsideDown",
    ]),
    "UISupportedInterfaceOrientations~iphone": .array([
      "UIInterfaceOrientationPortrait",
      "UIInterfaceOrientationLandscapeLeft",
      "UIInterfaceOrientationLandscapeRight",
    ]),
  ]),
  sources: ["Sources/**/*"],
  resources: ["Resources/**/*"],
  actions: [swiftFormat],
  dependencies: [.package(product: "GRDB")],
  settings: Settings(base: [
    "DEVELOPMENT_TEAM": "3CM92FF2C5",
    "PRODUCT_MODULE_NAME": "Fosdem",
  ]),
  environment: ["ENABLE_SCHEDULE_UPDATES": "1", "ENABLE_ONBOARDING": "1"]
)

let appTests = Target(
  name: "Tests",
  platform: app.platform,
  product: .unitTests,
  bundleId: "\(app.bundleId).tests",
  deploymentTarget: app.deploymentTarget,
  infoPlist: .default,
  sources: ["Tests/**"],
  resources: ["Tests/Resources/**/*", "Resources/Buildings/**/*"],
  actions: [swiftFormat],
  dependencies: [.target(name: app.name)]
)

let appUITests = Target(
  name: "UITests",
  platform: app.platform,
  product: .uiTests,
  bundleId: "\(app.bundleId).uitests",
  deploymentTarget: app.deploymentTarget,
  infoPlist: .default,
  sources: ["UITests/**/*", "Tests/BundleDataLoader.swift"],
  resources: ["UITests/Resources/**/*"],
  actions: [swiftFormat],
  dependencies: [.target(name: app.name)]
)

let dbGenerator = Target(
  name: "GenerateDB",
  platform: .macOS,
  product: .commandLineTool,
  bundleId: "\(app.bundleId).db-generator",
  deploymentTarget: .macOS(targetVersion: "10.13"),
  infoPlist: .default,
  sources: [
    "Scripts/GenerateDB.swift",
    "Sources/Models/**/*",
    "Sources/Services/NetworkService.swift",
    "Sources/Services/PersistenceService.swift",
    "Sources/Extensions/DateFormatter+Extensions.swift",
    "Sources/Extensions/DateComponentsFormatter+Extensions.swift",
  ],
  actions: [swiftFormat],
  dependencies: [.package(product: "GRDB")]
)

let project = Project(
  name: "FOSDEM",
  organizationName: "com.mttcrsp.fosdem",
  packages: [grdb],
  targets: [app, appTests, appUITests, dbGenerator, l10n, ui]
)
