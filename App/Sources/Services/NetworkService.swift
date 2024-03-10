import Foundation

protocol NetworkRequest {
  associatedtype Model

  var url: URL { get }
  var httpBody: Data? { get }
  var httpMethod: String { get }
  var allHTTPHeaderFields: [String: String]? { get }

  func decode(_ data: Data?, response: HTTPURLResponse?) throws -> Model
}

final class NetworkService {
  private let session: NetworkServiceSession

  init(session: NetworkServiceSession) {
    self.session = session
  }

  @discardableResult
  func perform<Request: NetworkRequest>(_ request: Request, completion: @escaping (Result<Request.Model, Error>) -> Void) -> NetworkServiceTask {
    let task = session.dataTask(with: request.httpRequest) { data, response, error in
      if let error = error as? URLError, error.code == .cancelled {
        return // Do nothing
      } else if let error {
        return completion(.failure(error))
      }

      do {
        let model = try request.decode(data, response: response as? HTTPURLResponse)
        completion(.success(model))
      } catch {
        completion(.failure(error))
      }
    }

    task.resume()
    return task
  }
}

extension NetworkRequest {
  var httpBody: Data? {
    nil
  }

  var httpMethod: String {
    "GET"
  }

  var allHTTPHeaderFields: [String: String]? {
    nil
  }
}

private extension NetworkRequest {
  var httpRequest: URLRequest {
    let request = NSMutableURLRequest(url: url)
    request.allHTTPHeaderFields = allHTTPHeaderFields
    request.httpMethod = httpMethod
    request.httpBody = httpBody
    return request as URLRequest
  }
}

/// @mockable
protocol NetworkServiceTask {
  func cancel()
  func resume()
}

extension URLSessionDataTask: NetworkServiceTask {}

/// @mockable
protocol NetworkServiceSession {
  func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> NetworkServiceTask
}

extension URLSession: NetworkServiceSession {
  func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> NetworkServiceTask {
    dataTask(with: request, completionHandler: completionHandler) as URLSessionDataTask
  }
}
