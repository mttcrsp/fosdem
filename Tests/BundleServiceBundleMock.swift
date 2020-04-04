@testable
import Fosdem
import Foundation

final class BundleServiceBundleMock: BundleServiceBundle {
    private(set) var name: String?
    private(set) var ext: String?
    private let url: URL?

    init(url: URL?) {
        self.url = url
    }

    func url(forResource name: String?, withExtension ext: String?) -> URL? {
        self.name = name
        self.ext = ext
        return url
    }
}
