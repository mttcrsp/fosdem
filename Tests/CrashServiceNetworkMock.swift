@testable
import Fosdem

final class CrashServiceNetworkMock: CrashServiceNetwork {
    private(set) var request: JSONBinRequest?
    private(set) var completion: ((Result<Void, Error>) -> Void)?

    func perform(_ request: JSONBinRequest, completion: @escaping (Result<Void, Error>) -> Void) -> NetworkServiceTask {
        self.request = request
        self.completion = completion
        return NetworkServiceTaskMock()
    }
}
