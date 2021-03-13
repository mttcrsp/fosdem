import ProjectDescription

let config = Config(
  compatibleXcodeVersions: .all,
  generationOptions: [
    .disableSynthesizedResourceAccessors,
    .enableCodeCoverage,
  ]
)
