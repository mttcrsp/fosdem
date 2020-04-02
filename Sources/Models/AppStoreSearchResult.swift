struct AppStoreSearchResult: Equatable, Decodable {
    let identifier: Int
    let version: String

    enum CodingKeys: String, CodingKey {
        case identifier = "trackId"
        case version
    }
}
