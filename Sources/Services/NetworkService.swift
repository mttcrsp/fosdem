import Foundation

protocol NetworkRequest {
    associatedtype Model

    var url: URL { get }

    func decode(_ data: Data) throws -> Model
}

protocol NetworkServiceTask {
    func resume()
}

protocol NetworkServiceSession {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> NetworkServiceTask
}

protocol NetworkServiceDelegate: AnyObject {
    func networkServiceDidBeginRequest(_ networkService: NetworkService)
    func networkServiceDidEndRequest(_ networkService: NetworkService)
}

final class NetworkService {
    weak var delegate: NetworkServiceDelegate?

    private let session: NetworkServiceSession

    init(session: NetworkServiceSession) {
        self.session = session
    }

    @discardableResult
    func perform<Request: NetworkRequest>(_ request: Request, completion: @escaping (Result<Request.Model, Error>) -> Void) -> NetworkServiceTask {
        let task = session.dataTask(with: request.url) { [weak self] data, _, error in
            if let self = self {
                self.delegate?.networkServiceDidEndRequest(self)
            }

            if let error = error {
                return completion(.failure(error))
            }

            do {
                let data = data ?? Data()
                let model = try request.decode(data)
                completion(.success(model))
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
        delegate?.networkServiceDidBeginRequest(self)

        return task
    }
}

extension URLSessionDataTask: NetworkServiceTask {}

extension URLSession: NetworkServiceSession {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> NetworkServiceTask {
        let task: URLSessionDataTask = dataTask(with: url, completionHandler: completionHandler)
        return task
    }
}
