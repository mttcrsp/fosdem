@testable
import Fosdem
import Foundation

struct PreloadServiceLaunchMock: PreloadServiceLaunch {
  let didLaunchAfterUpdate: Bool

  init(didLaunchAfterUpdate: Bool) {
    self.didLaunchAfterUpdate = didLaunchAfterUpdate
  }
}
