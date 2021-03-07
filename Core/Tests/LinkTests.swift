@testable
import Core
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
}
