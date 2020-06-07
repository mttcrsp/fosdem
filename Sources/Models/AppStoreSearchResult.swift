struct AppStoreSearchResult: Equatable, Decodable {
  let bundleIdentifier: String
  let version: String

  enum CodingKeys: String, CodingKey {
    case bundleIdentifier = "bundleId"
    case version
  }
}
