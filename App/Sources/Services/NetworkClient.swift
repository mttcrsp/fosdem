import Foundation

protocol NetworkRequest {
  associatedtype Model
  var url: URL { get }
  func decode(_ data: Data?, response: HTTPURLResponse?) throws -> Model
}

struct NetworkClient {
  var getFosdemApp: (@escaping (Result<AppStoreSearchResponse, Error>) -> Void) -> Void
  var getSchedule: (Year, @escaping (Result<Schedule, Error>) -> Void) -> NetworkClientTask
}

extension NetworkClient {
  init(session: NetworkClientSession) {
    @discardableResult
    func perform<Request: NetworkRequest>(_ request: Request, completion: @escaping (Result<Request.Model, Error>) -> Void) -> NetworkClientTask {
      let task = session.dataTask(with: request.httpRequest) { data, response, error in
        if let error = error as? URLError, error.code == .cancelled {
          return // Do nothing
        } else if let error = error {
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

    getFosdemApp = { completion in
      perform(GetFosdemApp(), completion: completion)
    }
    getSchedule = { year, completion in
      perform(GetSchedule(year: year), completion: completion)
    }
  }
}

private extension NetworkRequest {
  var httpRequest: URLRequest {
    let request = NSMutableURLRequest(url: url)
    return request as URLRequest
  }
}

/// @mockable
protocol NetworkClientTask {
  func cancel()
  func resume()
}

extension URLSessionDataTask: NetworkClientTask {}

/// @mockable
protocol NetworkClientSession {
  func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> NetworkClientTask
}

extension URLSession: NetworkClientSession {
  func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> NetworkClientTask {
    dataTask(with: request, completionHandler: completionHandler) as URLSessionDataTask
  }
}

struct GetFosdemApp: NetworkRequest {
  let url = URL(string: "https://itunes.apple.com/us/search?term=fosdem&media=software&entity=software")!
  func decode(_ data: Data?, response _: HTTPURLResponse?) throws -> AppStoreSearchResponse {
    try JSONDecoder().decode(AppStoreSearchResponse.self, from: data ?? Data())
  }
}

struct GetSchedule: NetworkRequest {
  enum Error: CustomNSError {
    case notFound
    case invalidParserResponse
  }

  let url: URL
  init(year: Int) {
    url = URL(string: "https://fosdem.org/")!
      .appendingPathComponent(year.description)
      .appendingPathComponent("schedule")
      .appendingPathComponent("xml")
  }

  func decode(_ data: Data?, response: HTTPURLResponse?) throws -> Schedule {
    guard let data = data, response?.statusCode != 404 else {
      throw Error.notFound
    }

    let parser = ScheduleXMLParser(data: data)
    if parser.parse(), let schedule = parser.schedule {
      return schedule
    } else if let error = parser.validationError {
      throw error
    } else if let error = parser.parseError {
      throw error
    } else {
      throw Error.invalidParserResponse
    }
  }
}
