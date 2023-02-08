import Foundation
import XCTest

final class BundleDataLoader {
  private let bundle: Bundle

  init(bundle: Bundle = Bundle(for: BundleDataLoader.self)) {
    self.bundle = bundle
  }

  func data(forResource resource: String, withExtension ext: String) throws -> Data {
    let url = try XCTUnwrap(bundle.url(forResource: resource, withExtension: ext))
    return try Data(contentsOf: url)
  }
}
