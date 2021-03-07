@testable
import Core
import Foundation

final class LiveServiceTimerMock: LiveServiceTimer {
  private(set) var didInvalidate = false

  weak var provider: LiveServiceProviderMock?

  func invalidate() {
    didInvalidate = true
    provider?.remove(self)
  }
}
