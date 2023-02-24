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

    completionHandler?(Data(), HTTPURLResponse(), nil)

    XCTAssertTrue(didExecuteCompletion)
  }

  func testPerformAdvancedRequest() throws {
    let request = AdvancedRequest()
    let dataTask = NetworkServiceTaskMock()
    let session = NetworkServiceSessionMock()

    var completionHandler: Completion?
    session.dataTaskHandler = { _, receivedCompletionHandler in
      completionHandler = receivedCompletionHandler
      return dataTask
    }

    let data = Data("something".utf8)
    let response = HTTPURLResponse(url: request.url, statusCode: 200, httpVersion: nil, headerFields: nil)
    let service = NetworkService(session: session)

    var didExecuteCompletion = false
    service.perform(request) { result in
      didExecuteCompletion = true

      switch result {
      case let .success(value):
        XCTAssertEqual(value.0, data)
        XCTAssertEqual(value.1, response)
      case let .failure(error):
        XCTFail(error.localizedDescription)
      }
    }

    XCTAssertEqual(dataTask.resumeCallCount, 1)
    XCTAssertEqual(session.dataTaskArgValues.first?.url, request.url)
    XCTAssertEqual(session.dataTaskArgValues.first?.httpBody, request.httpBody)
    XCTAssertEqual(session.dataTaskArgValues.first?.httpMethod, request.httpMethod)
    XCTAssertEqual(session.dataTaskArgValues.first?.allHTTPHeaderFields, request.allHTTPHeaderFields)

    completionHandler?(data, response, nil)

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
    let error = NSError(domain: "test", code: 1)
    let request = ThrowingRequest(error: error)
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
      case let .failure(receivedError as NSError):
        XCTAssertEqual(error, receivedError)
      }
    }

    completionHandler?(Data(), HTTPURLResponse(), nil)

    XCTAssertTrue(didExecuteCompletion)
  }

  private struct SimpleRequest: NetworkRequest {
    let url = URL(string: "https://www.fosdem.org")!

    func decode(_: Data?, response _: HTTPURLResponse?) throws {}
  }

  private struct AdvancedRequest: NetworkRequest {
    let url = URL(string: "https://www.fosdem.org")!
    let httpMethod = "POST"
    let httpBody = Data(base64Encoded: "fosdem")
    let allHTTPHeaderFields: [String: String]? = ["Content-Type": "application/json"]

    func decode(_ data: Data?, response: HTTPURLResponse?) throws -> (Data?, HTTPURLResponse?) {
      (data, response)
    }
  }

  private struct ThrowingRequest: NetworkRequest {
    let url = URL(string: "https://www.fosdem.org")!
    let error: NSError

    func decode(_: Data?, response _: HTTPURLResponse?) throws {
      throw error
    }
  }
}
