@testable
import Core

struct UpdateServiceBundleMock: UpdateServiceBundle {
  let bundleIdentifier: String?
  let bundleShortVersion: String?
}
