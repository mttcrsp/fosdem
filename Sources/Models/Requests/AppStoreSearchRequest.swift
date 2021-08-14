import Foundation

struct AppStoreSearchRequest: NetworkRequest {
  var url: URL {
    URL(string: "https://itunes.apple.com/us/search?term=fosdem&media=software&entity=software")!
  }

  func decode(_ data: Data?, response _: HTTPURLResponse?) throws -> AppStoreSearchResponse {
    try JSONDecoder().decode(AppStoreSearchResponse.self, from: data ?? Data())
  }
}
