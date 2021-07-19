import ProjectDescription

let mockolo = TargetAction.pre(
  script: "./mockolo.sh",
  name: "Mockolo"
)

let swiftFormat = TargetAction.post(
  script: "swiftformat .",
  name: "SwiftFormat"
)

let grdb = Package.remote(
  url: "https://github.com/mttcrsp/GRDB.swift",
  requirement: .branch("master")
)

let snapshotTesting = Package.remote(
  url: "https://github.com/pointfreeco/swift-snapshot-testing.git",
  requirement: .exact(.init(1, 8, 2))
)

let sbtUITestTunnel = Package.remote(
  url: "https://github.com/Subito-it/SBTUITestTunnel.git",
  requirement: .exact(.init(7, 0, 0))
)

let app = Target(
  name: "FOSDEM",
  platform: .iOS,
  product: .app,
  bundleId: "com.mttcrsp.fosdem",
  deploymentTarget: .iOS(targetVersion: "11.0", devices: [.iphone, .ipad]),
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
  actions: [mockolo, swiftFormat],
  dependencies: [
    .package(product: "GRDB"),
    .package(product: "GCDWebServer"),
    .package(product: "SBTUITestTunnelServer"),
    .sdk(name: "MobileCoreServices.framework", status: .required),
  ],
  settings: Settings(
    base: [
      "DEVELOPMENT_TEAM": "3CM92FF2C5",
      "PRODUCT_MODULE_NAME": "Fosdem",
    ],
    debug: Configuration(settings: [
      "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited) ENABLE_UITUNNEL",
    ])
  ),
  environment: ["ENABLE_SCHEDULE_UPDATES": "1", "ENABLE_ONBOARDING": "1"]
)

let appTests = Target(
  name: "Tests",
  platform: app.platform,
  product: .unitTests,
  bundleId: "\(app.bundleId).tests",
  deploymentTarget: app.deploymentTarget,
  infoPlist: .default,
  sources: ["Tests/**", "Mocks/**"],
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
  dependencies: [
    .target(name: app.name),
    .package(product: "SBTUITestTunnelClient"),
  ]
)

let appSnapshotTests = Target(
  name: "SnapshotTests",
  platform: app.platform,
  product: .unitTests,
  bundleId: "\(app.bundleId).snapshottests",
  deploymentTarget: app.deploymentTarget,
  infoPlist: .default,
  sources: ["SnapshotTests/**", "Mocks/**"],
  actions: [swiftFormat],
  dependencies: [
    .target(name: app.name),
    .package(product: "SnapshotTesting"),
  ]
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
  packages: [grdb, snapshotTesting, sbtUITestTunnel],
  targets: [app, appTests, appUITests, appSnapshotTests, dbGenerator]
)
