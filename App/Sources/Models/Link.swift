import Foundation

struct Link: Equatable, Codable {
  let name: String, url: URL?
}

extension Link {
  var isVideo: Bool {
    isMP4Video || isWEBMVideo
  }

  var isMP4Video: Bool {
    url?.host == "video.fosdem.org" && url?.pathExtension == "mp4"
  }

  var isWEBMVideo: Bool {
    url?.host == "video.fosdem.org" && url?.pathExtension == "webm"
  }
}

extension Link {
  var isLivestream: Bool {
    livestreamURL != nil
  }

  var livestreamURL: URL? {
    if let url, url.host == "live.fosdem.org", url.pathComponents.contains("watch"), let identifier = url.pathComponents.last {
      URL(string: "https://stream.fosdem.org")?.appendingPathComponent(identifier).appendingPathExtension("m3u8")
    } else {
      nil
    }
  }
}

extension Link {
  var isAddition: Bool {
    !isFeedback && !isChat && !isLivestream && !isVideo
  }

  private var isFeedback: Bool {
    if let url {
      url.host == "submission.fosdem.org" && url.pathComponents.contains("feedback")
    } else {
      false
    }
  }

  private var isChat: Bool {
    if let url {
      url.absoluteString.contains("chat.fosdem.org")
    } else {
      false
    }
  }
}
