@testable
import Core
import Foundation

final class BundleServiceMock {
  private(set) var name: String?
  private(set) var ext: String?

  private let result: Result<Data, Error>

  init(result: Result<Data, Error>) {
    self.result = result
  }

  func data(forResource name: String?, withExtension ext: String?) throws -> Data {
    self.name = name
    self.ext = ext

    switch result {
    case let .failure(error):
      throw error
    case let .success(value):
      return value
    }
  }
}

extension BundleServiceMock: BuildingsServiceBundle {}

#if os(iOS)
extension BundleServiceMock: InfoServiceBundle {}
#endif
