import Foundation

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

/// @mockable
protocol BundleServiceBundle {
  func url(forResource name: String?, withExtension ext: String?) -> URL?
}

extension Bundle: BundleServiceBundle {}

/// @mockable
protocol BundleServiceDataProvider {
  func data(withContentsOf url: URL) throws -> Data
}

final class BundleServiceData: BundleServiceDataProvider {
  func data(withContentsOf url: URL) throws -> Data {
    try Data(contentsOf: url)
  }
}

/// @mockable
protocol BundleServiceProtocol {
  func data(forResource name: String?, withExtension ext: String?) throws -> Data
}

extension BundleService: BundleServiceProtocol {}
