import XCTest

@objc(FOSTestObservationCenter)
final class TestObservationCenter: XCTestObservationCenter {
  override init() {
    super.init()

    let originalMethod = class_getInstanceMethod(XCUIApplication.self, #selector(XCUIApplication.launch))
    let swizzledMethod = class_getInstanceMethod(XCUIApplication.self, #selector(XCUIApplication.fos_launch))
    if let method1 = originalMethod, let method2 = swizzledMethod {
      method_exchangeImplementations(method1, method2)
    }
  }
}

@objc private extension XCUIApplication {
  func fos_launch() {
    launchArguments.append("-isRunningUITests")
    fos_launch()
  }
}
