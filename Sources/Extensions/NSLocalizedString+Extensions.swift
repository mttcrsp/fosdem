import Foundation

func FOSLocalizedString(_ key: String) -> String {
  NSLocalizedString(key, comment: "")
}

func FOSLocalizedString(format key: String, _ arguments: CVarArg...) -> String {
  let format = NSLocalizedString(key, comment: "")
  return String(format: format, arguments: arguments)
}
