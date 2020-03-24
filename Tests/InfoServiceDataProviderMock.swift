@testable
import Fosdem
import Foundation

final class InfoServiceDataProviderMock: InfoServiceDataProvider {
    private(set) var url: URL?
    private let data: Data

    init(data: Data) {
        self.data = data
    }

    func data(withContentsOf url: URL) throws -> Data {
        self.url = url
        return data
    }
}
