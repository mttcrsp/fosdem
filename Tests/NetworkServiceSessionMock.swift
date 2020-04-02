@testable
import Fosdem
import Foundation

final class NetworkServiceSessionMock: NetworkServiceSession {
    private(set) var url: URL?
    private(set) var completionHandler: ((Data?, URLResponse?, Error?) -> Void)?

    private let dataTask: NetworkServiceTask

    init(dataTask: NetworkServiceTask) {
        self.dataTask = dataTask
    }

    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> NetworkServiceTask {
        self.url = url
        self.completionHandler = completionHandler
        return dataTask
    }
}
