@testable
import Fosdem
import XCTest

final class NetworkServiceTests: XCTestCase {
  private typealias Completion = (Data?, URLResponse?, Error?) -> Void

  func testPerformSimpleRequest() {
    let request = SimpleRequest()
    let dataTask = NetworkServiceTaskMock()
    let session = NetworkServiceSessionMock()

    var completionHandler: Completion?
    session.dataTaskHandler = { _, receivedCompletionHandler in
      completionHandler = receivedCompletionHandler
      return dataTask
    }

    let service = NetworkService(session: session)

    var didExecuteCompletion = false
    service.perform(request) { result in
      didExecuteCompletion = true

      if case let .failure(error) = result {
        XCTFail(error.localizedDescription)
      }
    }

    XCTAssertEqual(dataTask.resumeCallCount, 1)
    XCTAssertNil(session.dataTaskArgValues.first?.httpBody)
    XCTAssertEqual(session.dataTaskArgValues.first?.url, request.url)
    XCTAssertEqual(session.dataTaskArgValues.first?.httpMethod, "GET")
    XCTAssertEqual(session.dataTaskArgValues.first?.allHTTPHeaderFields, [:])

    completionHandler?(Data(), nil, nil)

    XCTAssertTrue(didExecuteCompletion)
  }

  func testPerformAdvancedRequest() throws {
    let integer = 99
    let request = AdvancedRequest()
    let dataTask = NetworkServiceTaskMock()
    let session = NetworkServiceSessionMock()

    var completionHandler: Completion?
    session.dataTaskHandler = { _, receivedCompletionHandler in
      completionHandler = receivedCompletionHandler
      return dataTask
    }

    let service = NetworkService(session: session)

    var didExecuteCompletion = false
    service.perform(request) { result in
      didExecuteCompletion = true

      switch result {
      case let .success(value):
        XCTAssertEqual(value, integer)
      case let .failure(error):
        XCTFail(error.localizedDescription)
      }
    }

    XCTAssertEqual(dataTask.resumeCallCount, 1)
    XCTAssertEqual(session.dataTaskArgValues.first?.url, request.url)
    XCTAssertEqual(session.dataTaskArgValues.first?.httpBody, request.httpBody)
    XCTAssertEqual(session.dataTaskArgValues.first?.httpMethod, request.httpMethod)
    XCTAssertEqual(session.dataTaskArgValues.first?.allHTTPHeaderFields, request.allHTTPHeaderFields)

    let data = try JSONEncoder().encode(integer)

    completionHandler?(data, nil, nil)

    XCTAssertTrue(didExecuteCompletion)
  }

  func testPerformError() {
    let error = NSError(domain: "test", code: 1)
    let request = AdvancedRequest()
    let dataTask = NetworkServiceTaskMock()
    let session = NetworkServiceSessionMock()

    var completionHandler: Completion?
    session.dataTaskHandler = { _, receivedCompletionHandler in
      completionHandler = receivedCompletionHandler
      return dataTask
    }

    let service = NetworkService(session: session)

    var didExecuteCompletion = false
    service.perform(request) { result in
      didExecuteCompletion = true

      switch result {
      case .success:
        XCTFail("Request unexpectedly succeeded")
      case let .failure(otherError):
        XCTAssertEqual(otherError as NSError, error)
      }
    }

    completionHandler?(nil, nil, error)

    XCTAssertTrue(didExecuteCompletion)
  }

  func testPerformDecodingError() {
    let request = AdvancedRequest()
    let dataTask = NetworkServiceTaskMock()
    let session = NetworkServiceSessionMock()

    var completionHandler: Completion?
    session.dataTaskHandler = { _, receivedCompletionHandler in
      completionHandler = receivedCompletionHandler
      return dataTask
    }

    let service = NetworkService(session: session)

    var didExecuteCompletion = false
    service.perform(request) { result in
      didExecuteCompletion = true

      switch result {
      case .success:
        XCTFail("Request unexpectedly succeeded")
      case let .failure(error):
        XCTAssert(error is DecodingError)
      }
    }

    completionHandler?(nil, nil, nil)

    XCTAssertTrue(didExecuteCompletion)
  }

  private struct SimpleRequest: NetworkRequest {
    var url: URL {
      URL(string: "https://www.fosdem.org")!
    }

    func decode(_: Data) throws {}
  }

  private struct AdvancedRequest: NetworkRequest {
    var url: URL {
      URL(string: "https://www.fosdem.org")!
    }

    var httpMethod: String {
      "POST"
    }

    var httpBody: Data? {
      Data(base64Encoded: "fosdem")
    }

    var allHTTPHeaderFields: [String: String]? {
      ["Content-Type": "application/json"]
    }

    func decode(_ data: Data) throws -> Int {
      try JSONDecoder().decode(Int.self, from: data)
    }
  }
}
