@testable
import Fosdem
import Foundation

final class AcknowledgementsServiceDataProviderMock: AcknowledgementsServiceDataProvider {
    private(set) var url: URL?
    private let data: Result<Data, Error>

    init(data: Result<Data, Error>) {
        self.data = data
    }

    func data(withContentsOf url: URL) throws -> Data {
        self.url = url

        switch data {
        case let .success(data): return data
        case let .failure(error): throw error
        }
    }
}
