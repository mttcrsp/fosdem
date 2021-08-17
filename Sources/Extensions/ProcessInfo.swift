#if DEBUG
import Foundation

extension ProcessInfo {
  var isRunningUnitTests: Bool {
    environment["XCTestBundlePath"] != nil
  }
}
#endif
