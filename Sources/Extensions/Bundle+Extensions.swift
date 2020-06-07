import Foundation

extension Bundle {
  var bundleShortVersion: String? {
    object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
  }
}
