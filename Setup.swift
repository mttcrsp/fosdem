import Foundation
import ProjectDescription

let isCI: Bool = {
  if let path = ProcessInfo.processInfo.environment["DYLD_LIBRARY_PATH"], path.contains("/Users/runner") {
    return true
  } else {
    return false
  }
}()

let runMockolo = Up.custom(
  name: "Run Mockolo",
  meet: ["./run-mockolo"],
  isMet: ["test -f Tests/Mockolo.swift"]
)

let setup: Setup = {
  guard isCI else {
    return Setup([
      .homebrew(packages: ["swiftformat", "mockolo"]),
      runMockolo,
    ])
  }

  return Setup([
    // Latest formulae of Mockolo rely on a full installation of Xcode being
    // available (not just command line tools). Since this is not available on
    // CI, in such environments the tool can't be downloaded via Homebrew.
    .custom(
      name: "Install Mockolo",
      meet: ["./install-mockolo"],
      isMet: ["test -f mockolo"]
    ),
    runMockolo,
  ])
}()
