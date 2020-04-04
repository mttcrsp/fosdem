@testable
import Fosdem
import Foundation

final class BundleServiceDataProviderMock: BundleServiceDataProvider {
    private(set) var url: URL?

    private let result: Result<Data, Error>

    init(result: Result<Data, Error>) {
        self.result = result
    }

    func data(withContentsOf url: URL) throws -> Data {
        self.url = url

        switch result {
        case let .failure(error): throw error
        case let .success(value): return value
        }
    }
}
