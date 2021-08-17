#if DEBUG
import Foundation

extension ProcessInfo {
  var isRunningUnitTests: Bool {
    arguments.contains("-ApplePersistenceIgnoreState")
  }
}
#endif
