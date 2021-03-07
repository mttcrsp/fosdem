@testable
import Core
import Foundation

final class NetworkServiceSessionMock: NetworkServiceSession {
  private(set) var completionHandler: ((Data?, URLResponse?, Error?) -> Void)?
  private(set) var request: URLRequest?

  private let dataTask: NetworkServiceTask

  init(dataTask: NetworkServiceTask) {
    self.dataTask = dataTask
  }

  func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> NetworkServiceTask {
    self.completionHandler = completionHandler
    self.request = request
    return dataTask
  }
}
