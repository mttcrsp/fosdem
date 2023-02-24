import UIKit

var app: UIApplication.Type = App.self
var appDelegate: UIApplicationDelegate.Type = AppDelegate.self

#if DEBUG
private final class TestApp: UIApplication {}
private final class TestAppDelegate: NSObject, UIApplicationDelegate {}

if ProcessInfo.processInfo.environment["XCTestBundlePath"] != nil {
  app = TestApp.self
  appDelegate = TestAppDelegate.self
}
#endif

UIApplicationMain(
  CommandLine.argc,
  CommandLine.unsafeArgv,
  NSStringFromClass(app),
  NSStringFromClass(appDelegate)
)
