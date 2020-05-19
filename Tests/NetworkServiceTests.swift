@testable
import Fosdem
import XCTest

final class NetworkServiceTests: XCTestCase {
    func testPerform() {
        let integer = 99
        let request = Request()
        let dataTask = NetworkServiceTaskMock()
        let session = NetworkServiceSessionMock(dataTask: dataTask)
        let service = NetworkService(session: session)

        var didExecuteCompletion = false
        service.perform(request) { result in
            didExecuteCompletion = true

            switch result {
            case let .success(value): XCTAssertEqual(value, integer)
            case let .failure(error): XCTFail(error.localizedDescription)
            }
        }

        XCTAssertTrue(dataTask.didResume)
        XCTAssertEqual(session.request?.url, request.url)
        XCTAssertEqual(session.request?.httpBody, request.httpBody)
        XCTAssertEqual(session.request?.httpMethod, request.httpMethod)
        XCTAssertEqual(session.request?.allHTTPHeaderFields, request.allHTTPHeaderFields)

        guard let completionHandler = session.completionHandler else {
            return XCTAssertNotNil(session.completionHandler)
        }

        do {
            let data = try JSONEncoder().encode(integer)
            completionHandler(data, nil, nil)

            XCTAssertTrue(didExecuteCompletion)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testPerformError() {
        let error = NSError(domain: "test", code: 1)
        let request = Request()
        let dataTask = NetworkServiceTaskMock()
        let session = NetworkServiceSessionMock(dataTask: dataTask)
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

        session.completionHandler?(nil, nil, error)

        XCTAssertTrue(didExecuteCompletion)
    }

    func testPerformDecodingError() {
        let request = Request()
        let dataTask = NetworkServiceTaskMock()
        let session = NetworkServiceSessionMock(dataTask: dataTask)
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

        session.completionHandler?(nil, nil, nil)

        XCTAssertTrue(didExecuteCompletion)
    }

    private struct Request: NetworkRequest {
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
