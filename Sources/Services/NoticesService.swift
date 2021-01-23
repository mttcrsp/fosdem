import Foundation

final class NoticesService {
  private let defaults = UserDefaults.standard
  private let currentYear: Int

  init(currentYear: Int) {
    self.currentYear = currentYear
  }

  private var didDisplay2021Notice: Bool {
    get { defaults.didDisplay2021Notice }
    set { defaults.didDisplay2021Notice = newValue }
  }

  var shouldDisplay2021Notice: Bool {
    currentYear == 2021 && !didDisplay2021Notice
  }

  func mark2021NoticeDisplayed() {
    didDisplay2021Notice = true
  }
}

private extension UserDefaults {
  var didDisplay2021Notice: Bool {
    get { bool(forKey: .didDisplay2021NoticeKey) }
    set { set(newValue, forKey: .didDisplay2021NoticeKey) }
  }
}

private extension String {
  static var didDisplay2021NoticeKey: String { "DID_DISPLAY_2021_NOTICE" }
}
