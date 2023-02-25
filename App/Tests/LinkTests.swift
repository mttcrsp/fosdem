@testable
import Fosdem
import XCTest

final class LinkTests: XCTestCase {
  func testLivestreamURL1() {
    let link = Link(name: "test", url: URL(string: "https://live.fosdem.org/watch/mcommunity"))
    XCTAssertEqual(link.livestreamURL, URL(string: "https://stream.fosdem.org/mcommunity.m3u8"))
  }

  func testLivestreamURL2() {
    let link = Link(name: "test", url: URL(string: "https://live.fosdem.org/watch/dwebperformance"))
    XCTAssertEqual(link.livestreamURL, URL(string: "https://stream.fosdem.org/dwebperformance.m3u8"))
  }

  func testIsLivestream() {
    let link = Link(name: "test", url: URL(string: "https://live.fosdem.org/watch/dwebperformance"))
    XCTAssertTrue(link.isLivestream)
  }

  func testIsMP4Video() {
    let link = Link(name: "test", url: URL(string: "https://video.fosdem.org/2023/Janson/celebrating_25_years_of_open_source.mp4"))
    XCTAssertTrue(link.isMP4Video)
  }

  func testIsWEBMVideo() {
    let link = Link(name: "test", url: URL(string: "https://video.fosdem.org/2023/Janson/celebrating_25_years_of_open_source.webm"))
    XCTAssertTrue(link.isWEBMVideo)
  }

  func testIsVideoMP4() {
    let link = Link(name: "test", url: URL(string: "https://video.fosdem.org/2023/Janson/celebrating_25_years_of_open_source.webm"))
    XCTAssertTrue(link.isVideo)
  }

  func testIsVideoWEBM() {
    let link = Link(name: "test", url: URL(string: "https://video.fosdem.org/2023/Janson/celebrating_25_years_of_open_source.mp4"))
    XCTAssertTrue(link.isVideo)
  }

  func testIsAddition() {
    let link = Link(name: "test", url: URL(string: "https://anniv.co"))
    XCTAssertTrue(link.isAddition)
  }

  func testIsAdditionIgnoresFeedback() {
    let link = Link(name: "test", url: URL(string: "https://submission.fosdem.org/feedback/14956.php"))
    XCTAssertFalse(link.isAddition)
  }

  func testIsAdditionIgnoresChatWeb() throws {
    let url = try XCTUnwrap(URLComponents(string: "https://chat.fosdem.org/#/room/#2023-janson:fosdem.org")?.url)
    let link = Link(name: "test", url: url)
    XCTAssertFalse(link.isAddition)
  }

  func testIsAdditionIgnoresChatMatrix() throws {
    let url = try XCTUnwrap(URLComponents(string: "https://matrix.to/#/#2023-janson:fosdem.org?web-instance[element.io]=chat.fosdem.org")?.url)
    let link = Link(name: "test", url: url)
    XCTAssertFalse(link.isAddition)
  }
}
