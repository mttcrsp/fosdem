import Foundation

struct Link: Equatable, Codable {
  let name: String, url: URL?
}

extension Link {
  var isLivestream: Bool {
    livestreamURL != nil
  }

  var livestreamURL: URL? {
    guard let host = url?.host, let pathComponents = url?.pathComponents else {
      return nil
    }

    if host == "live.fosdem.org", pathComponents.contains("watch"), let identifier = pathComponents.last {
      return URL(string: "https://stream.fosdem.org")?.appendingPathComponent(identifier).appendingPathExtension("m3u8")
    } else {
      return nil
    }
  }
}
