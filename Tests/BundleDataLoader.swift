import Foundation
import XCTest

final class BundleDataLoader {
  private let bundle: Bundle

  init(bundle: Bundle = .default) {
    self.bundle = bundle
  }

  func data(forResource resource: String, withExtension ext: String) -> Data? {
    guard let url = Bundle(for: Self.self).url(forResource: resource, withExtension: ext) else {
      XCTFail("Unable to locate resource '\(resource)' with extension \(ext)")
      return nil
    }

    guard let data = try? Data(contentsOf: url) else {
      XCTFail("Unable to load data at url '\(url)'")
      return nil
    }

    return data
  }
}

private extension Bundle {
  static var `default`: Bundle {
    .init(for: BundleDataLoader.self)
  }
}
