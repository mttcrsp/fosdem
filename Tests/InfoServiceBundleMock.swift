@testable
import Fosdem
import Foundation

final class InfoServiceBundleMock: InfoServiceBundle {
    private(set) var name: String?
    private(set) var ext: String?

    private let data: Data

    init(data: Data) {
        self.data = data
    }

    func data(forResource name: String?, withExtension ext: String?) throws -> Data {
        self.name = name
        self.ext = ext
        return data
    }
}
