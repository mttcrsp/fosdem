@testable
import Fosdem
import SnapshotTesting
import XCTest

final class EventViewControllerTests: XCTestCase {
  private let size = CGSize(width: 375, height: 1024)

  func testAppearance() throws {
    let dataSource = EventViewControllerDataSourceMock()
    dataSource.eventViewControllerHandler = { _, _ in .beginning }

    let eventViewController = EventViewController()
    eventViewController.event = try .withVideo()
    eventViewController.dataSource = dataSource
    eventViewController.view.tintColor = .label
    assertSnapshot(matching: eventViewController, as: .image(size: size))

    dataSource.eventViewControllerHandler = { _, _ in .at(9) }
    eventViewController.reloadPlaybackPosition()
    assertSnapshot(matching: eventViewController, as: .image(size: size))

    dataSource.eventViewControllerHandler = { _, _ in .end }
    eventViewController.reloadPlaybackPosition()
    assertSnapshot(matching: eventViewController, as: .image(size: size))

    let eventViewController = EventViewController(style: .insetGrouped)
    eventViewController.event = try .withVideo()
    eventViewController.dataSource = dataSource
    eventViewController.view.tintColor = .label
    assertSnapshot(matching: eventViewController, as: .image(size: size))
  }

  func testEvents() throws {
    let delegate = EventViewControllerDelegateMock()

    var eventViewController = EventViewController()
    eventViewController.delegate = delegate
    eventViewController.event = try .withVideo()
    assertSnapshot(matching: eventViewController, as: .image(size: size))

    let attachmentView = eventViewController.view.findSubview(ofType: EventAdditionsItemView.self)
    attachmentView?.sendActions(for: .touchUpInside)
    XCTAssertEqual(delegate.eventViewControllerCallCount, 1)
    XCTAssertEqual(delegate.eventViewControllerArgValues.first?.0, eventViewController)
    XCTAssertEqual(delegate.eventViewControllerArgValues.first?.1, eventViewController.event?.attachments.first?.url)

    let videoButton = eventViewController.view.findSubview(ofType: RoundedButton.self, accessibilityIdentifier: "play")
    videoButton?.sendActions(for: .touchUpInside)
    XCTAssertEqual(delegate.eventViewControllerDidTapVideoArgValues, [eventViewController])

    eventViewController = EventViewController()
    eventViewController.delegate = delegate
    eventViewController.showsLivestream = true
    eventViewController.event = try .withLivestream()
    assertSnapshot(matching: eventViewController, as: .image(size: size))
    XCTAssertTrue(eventViewController.showsLivestream)

    let livestreamButton = eventViewController.view.findSubview(ofType: RoundedButton.self, accessibilityIdentifier: "livestream")
    livestreamButton?.sendActions(for: .touchUpInside)
    XCTAssertEqual(delegate.eventViewControllerDidTapLivestreamArgValues, [eventViewController])
  }
}

private extension Event {
  static func withVideo() throws -> Event {
    try Event.from(#"{ "room": "D.go", "people": [{ "id": 7738, "name": "Sean DuBois" }], "start": { "minute": 0, "hour": 15 }, "id": 11142, "track": "Go", "title": "Drones, Virtual Reality and Multiplayer NES Games. The fun you can have with Pion WebRTC!", "date": 641049424.05467796, "abstract": "<p>In 2020 we saw a huge spike in interest for RTC. Developers worked quickly to\nbuild new tools with the challenge of a socially distanced world. Go has really started\nto make strides in the RTC world with Pion. Easy deploy, great performance, memory safety\nand ability to prototype helped it take on C/C++.</p><p>This talk shows you some basics on WebRTC, then how to use Pion and what you can build with it</p>", "duration": { "minute": 30 }, "links": [ { "name": "Video recording (WebM/VP9)", "url": "https://video.fosdem.org/2021/D.go/gowithoutwires.webm" }, { "name": "Video recording (mp4)", "url": "https://video.fosdem.org/2021/D.go/gowithoutwires.mp4" }, { "name": "Submit feedback", "url": "https://submission.fosdem.org/feedback/11142.php" } ], "attachments": [ { "type": "slides", "url": "https://fosdem.org/2021/schedule/event/gowebrtc/attachments/slides/4583/export/events/attachments/gowebrtc/slides/4583/Slides.pdf", "name": "Slides" } ] }"#)
  }

  static func withLivestream() throws -> Event {
    try Event.from(#"{"room": "D.go", "people": [{ "id": 7738, "name": "Sean DuBois" }], "start": { "minute": 0, "hour": 15 }, "id": 11142, "track": "Go", "title": "Drones, Virtual Reality and Multiplayer NES Games. The fun you can have with Pion WebRTC!", "date": 641049424.05467796, "abstract": "<p>In 2020 we saw a huge spike in interest for RTC. Developers worked quickly to\nbuild new tools with the challenge of a socially distanced world. Go has really started\nto make strides in the RTC world with Pion. Easy deploy, great performance, memory safety\nand ability to prototype helped it take on C/C++.</p><p>This talk shows you some basics on WebRTC, then how to use Pion and what you can build with it</p>", "duration": { "minute": 30 }, "links": [{"name": "Submit feedback", "url": "https://submission.fosdem.org/feedback/11142.php"}, {"name": "Live video stream from the room (during event)", "url": "https://live.fosdem.org/watch/dgo"} ], "attachments": [{"type": "slides", "url": "https://fosdem.org/2021/schedule/event/gowebrtc/attachments/slides/4583/export/events/attachments/gowebrtc/slides/4583/Slides.pdf", "name": "Slides"} ] }"#)
  }
}
