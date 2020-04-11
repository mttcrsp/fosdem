import Foundation

protocol BundleServiceBundle {
    func url(forResource name: String?, withExtension ext: String?) -> URL?
}

protocol BundleServiceDataProvider {
    func data(withContentsOf url: URL) throws -> Data
}

final class BundleService {
    enum Error: CustomNSError {
        case resourceNotFound
    }

    private let dataProvider: BundleServiceDataProvider
    private let bundle: BundleServiceBundle

    init(bundle: BundleServiceBundle = Bundle.main, dataProvider: BundleServiceDataProvider = BundleServiceData()) {
        self.dataProvider = dataProvider
        self.bundle = bundle
    }

    func data(forResource name: String?, withExtension ext: String?) throws -> Data {
        guard let url = bundle.url(forResource: name, withExtension: ext) else {
            throw Error.resourceNotFound
        }
        return try dataProvider.data(withContentsOf: url)
    }
}

extension Bundle: BundleServiceBundle {}

final class BundleServiceData: BundleServiceDataProvider {
    func data(withContentsOf url: URL) throws -> Data {
        try Data(contentsOf: url)
    }
}

extension BundleService.Error {
    var localizedDescription: String {
        "Unable to locate the requested resource"
    }

    static var errorDomain: String {
        "org.fosdem.fosdem.\(String(describing: BundleService.self))"
    }
}
