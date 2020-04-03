@testable
import Fosdem

struct UpdateServiceBundleMock: UpdateServiceBundle {
    let bundleIdentifier: String?
    let bundleShortVersion: String?
}
