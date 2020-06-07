import Foundation

struct JSONBinRequest: NetworkRequest {
  let secretKey: String
  let data: Data

  var url: URL {
    URL(string: "https://api.jsonbin.io/b")!
  }

  var httpMethod: String {
    "POST"
  }

  var httpBody: Data? {
    let payload = JSONBinPayload(base64: data.base64EncodedString())
    let encoder = JSONEncoder()
    let encoded = try? encoder.encode(payload)
    return encoded
  }

  var allHTTPHeaderFields: [String: String]? {
    ["Content-Type": "application/json", "secret-key": secretKey]
  }

  func decode(_: Data) throws {}
}
