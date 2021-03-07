@testable
import Core

final class NetworkServiceTaskMock: NetworkServiceTask {
  private(set) var didResume = false

  func resume() {
    didResume = true
  }
}
