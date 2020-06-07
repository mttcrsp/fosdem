@testable
import Fosdem

final class PreloadServiceBundleMock: PreloadServiceBundle {
  private(set) var name: String?
  private(set) var ext: String?
  private let path: String?

  init(path: String?) {
    self.path = path
  }

  func path(forResource name: String?, ofType ext: String?) -> String? {
    self.name = name
    self.ext = ext
    return path
  }
}
