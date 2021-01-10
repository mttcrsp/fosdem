#if DEBUG
import Foundation

extension ProcessInfo {
  var isRunningUnitTests: Bool {
    arguments.contains("-ApplePersistenceIgnoreState")
  }

  var isRunningUITests: Bool {
    arguments.contains("-isRunningUITests")
  }
}
#endif
