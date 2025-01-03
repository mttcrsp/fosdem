import AVKit
@testable
import Fosdem
import SafariServices
import SnapshotTesting
import XCTest

final class EventControllerTests: XCTestCase {
  class Dependencies: EventController.Dependencies {
    var playbackService: PlaybackServiceProtocol = {
      let playbackService = PlaybackServiceProtocolMock()
      playbackService.playbackPositionHandler = { _ in .beginning }
      return playbackService
    }()

    var favoritesService: FavoritesServiceProtocol = {
      let favoritesService = FavoritesServiceProtocolMock()
      favoritesService.addObserverForEventsHandler = { _ in NSObject() }
      return favoritesService
    }()

    var timeService: TimeServiceProtocol = {
      let calendar = Calendar.gregorian
      let timeZone = TimeZone(identifier: "Europe/Brussels")
      let components = DateComponents(timeZone: timeZone, year: 2021, month: 2, day: 6, hour: 12, minute: 45)
      let timeService = TimeServiceProtocolMock()
      timeService.now = calendar.date(from: components) ?? Date()
      return timeService
    }()

    var navigationService: NavigationServiceProtocol = {
      let navigationService = NavigationServiceProtocolMock()
      navigationService.makePlayerViewControllerHandler = PlayerViewController.init
      navigationService.makeSafariViewControllerHandler = SafariViewController.init
      return navigationService
    }()
  }

  override class func setUp() {
    super.setUp()
    UITableView.appearance().showsVerticalScrollIndicator = false
  }

  override class func tearDown() {
    UITableView.appearance().showsVerticalScrollIndicator = true
    super.tearDown()
  }

  func testAppearance() throws {
    var eventController = try EventController(event: .withVideo(), dependencies: Dependencies())
    let navigationController = UINavigationController(rootViewController: eventController)
    assertSnapshot(matching: navigationController, as: .image(on: .iPhone8Plus))

    eventController.showsFavoriteButton = false
    assertSnapshot(matching: navigationController, as: .image(on: .iPhone8Plus))

    eventController.showsFavoriteButton = true
    assertSnapshot(matching: navigationController, as: .image(on: .iPhone8Plus))

    eventController = try EventController(event: .withLivestream(), dependencies: Dependencies())
    navigationController.viewControllers = [eventController]
    assertSnapshot(matching: navigationController, as: .image(on: .iPhone8Plus))

    eventController = try EventController(event: .withLivestream(), dependencies: Dependencies())
    navigationController.viewControllers = [eventController]
    assertSnapshot(matching: navigationController, as: .image(on: .iPadPro11))
  }

  func testFavoriteNotification() throws {
    let favoritesService = FavoritesServiceProtocolMock()
    let dependencies = Dependencies()
    dependencies.favoritesService = favoritesService

    let token = NSObject()
    var observer: (() -> Void)?
    favoritesService.addObserverForEventsHandler = { receivedObserver in
      observer = receivedObserver
      return token
    }

    try autoreleasepool {
      let eventController: EventController! = try EventController(event: .withVideo(), dependencies: dependencies)
      let navigationController = UINavigationController(rootViewController: eventController)
      assertSnapshot(matching: navigationController, as: .image(on: .iPhone8Plus))
      XCTAssertEqual(favoritesService.addObserverForEventsCallCount, 1)

      favoritesService.containsHandler = { _ in true }
      observer?()
      assertSnapshot(matching: navigationController, as: .image(on: .iPhone8Plus))

      favoritesService.containsHandler = { _ in false }
      observer?()
      assertSnapshot(matching: navigationController, as: .image(on: .iPhone8Plus))

      // Kill UINavigationController -> EventController reference to force
      // deallocation of the latter
      navigationController.viewControllers = []
    }

    XCTAssertEqual(favoritesService.removeObserverArgValues as? [NSObject], [token])
  }

  func testFavoriteEvents() throws {
    let favoritesService = FavoritesServiceProtocolMock()
    favoritesService.addObserverForEventsHandler = { _ in NSObject() }

    let dependencies = Dependencies()
    dependencies.favoritesService = favoritesService

    let eventController = try EventController(event: .withVideo(), dependencies: dependencies)
    assertSnapshot(matching: eventController, as: .image(on: .iPhone8Plus))

    let eventID = eventController.event.id

    let favoriteButton = eventController.navigationItem.rightBarButtonItem
    let target = try XCTUnwrap(favoriteButton?.target)
    let action = try XCTUnwrap(favoriteButton?.action)

    favoritesService.containsHandler = { _ in false }
    _ = target.perform(action)
    XCTAssertEqual(favoritesService.addEventArgValues, [eventID])

    favoritesService.containsHandler = { _ in true }
    _ = target.perform(action)
    XCTAssertEqual(favoritesService.removeEventArgValues, [eventID])
  }

  func testAudioSessionHandling() throws {
    let audioSession = AVAudioSessionProtocolMock()

    try autoreleasepool {
      let eventController = try EventController(event: .withLivestream(), dependencies: Dependencies(), audioSession: audioSession)
      eventController.playerViewController(AVPlayerViewController(), willBeginFullScreenPresentationWithAnimationCoordinator: UIViewControllerTransitionCoordinatorMock())
      XCTAssertEqual(audioSession.setActiveArgValues.map(\.0), [true])
    }

    XCTAssertEqual(audioSession.setActiveArgValues.map(\.0), [true, false])
  }

  func testPlaybackPositionUpdates() throws {
    let playerViewController = AVPlayerViewController()

    let navigationService = NavigationServiceProtocolMock()
    navigationService.makePlayerViewControllerHandler = { playerViewController }

    let playbackService = PlaybackServiceProtocolMock()
    playbackService.playbackPositionHandler = { _ in .beginning }

    let dependencies = Dependencies()
    dependencies.playbackService = playbackService
    dependencies.navigationService = navigationService

    let notificationCenter = NotificationCenter()
    let observer = NSObject()
    let player = Player()

    var addInterval: CMTime?
    var addQueue: DispatchQueue?
    var addBlock: ((CMTime) -> Void)?
    player.addPeriodicTimeObserverHandler = { interval, queue, block in
      addInterval = interval
      addQueue = queue
      addBlock = block
      return observer
    }

    var removedObserver: Any?
    player.removeTimeObserverHandler = { observer in
      removedObserver = observer
    }

    try autoreleasepool {
      let event = try Event.withVideo()
      let eventController = EventController(event: event, dependencies: dependencies, notificationCenter: notificationCenter)

      let eventViewController = EventViewController()
      eventViewController.event = event
      eventController.eventViewControllerDidTapVideo(eventViewController)

      playerViewController.player = player
      eventController.playerViewController(playerViewController, willBeginFullScreenPresentationWithAnimationCoordinator: UIViewControllerTransitionCoordinatorMock())

      let intervalScale = CMTimeScale(NSEC_PER_SEC)
      let interval = CMTime(seconds: 0.1, preferredTimescale: intervalScale)

      playbackService.playbackPositionHandler = { _ in .at(99) }
      addBlock?(CMTime(seconds: 99, preferredTimescale: intervalScale))
      XCTAssertEqual(addQueue, .main)
      XCTAssertEqual(addInterval, interval)
      XCTAssertEqual(playbackService.setPlaybackPositionArgValues.map(\.0), [.at(99)])
      XCTAssertEqual(playbackService.setPlaybackPositionArgValues.map(\.1), [event.id])

      playbackService.playbackPositionHandler = { _ in .end }
      notificationCenter.post(name: .AVPlayerItemDidPlayToEndTime, object: nil, userInfo: nil)
      XCTAssertEqual(playbackService.setPlaybackPositionArgValues.map(\.0), [.at(99), .end])
      XCTAssertEqual(playbackService.setPlaybackPositionArgValues.map(\.1), [event.id, event.id])
    }

    /// `assertSnapshot` introduces a strong reference to its input view
    /// controller that only breaks once the test exits. This means that the you
    /// cannot tests deallocation together with snapshots.
    XCTAssertEqual(removedObserver as? NSObject, observer)
  }

  func testPlaybackPositionUpdatesUI() throws {
    let playbackService = PlaybackServiceProtocolMock()
    playbackService.playbackPositionHandler = { _ in .beginning }

    let dependencies = Dependencies()
    dependencies.playbackService = playbackService

    let notificationCenter = NotificationCenter()
    let player = Player()

    var addBlock: ((CMTime) -> Void)?
    player.addPeriodicTimeObserverHandler = { _, _, block in
      addBlock = block
      return NSObject()
    }

    let event = try Event.withVideo()
    let eventController = EventController(event: event, dependencies: dependencies, notificationCenter: notificationCenter)
    assertSnapshot(matching: eventController, as: .image(on: .iPhone8Plus))

    let eventViewController = EventViewController()
    eventViewController.event = event

    let playerViewController = AVPlayerViewController()
    playerViewController.player = player

    eventController.playerViewController(playerViewController, willBeginFullScreenPresentationWithAnimationCoordinator: UIViewControllerTransitionCoordinatorMock())

    let intervalScale = CMTimeScale(NSEC_PER_SEC)
    playbackService.playbackPositionHandler = { _ in .at(99) }
    addBlock?(CMTime(seconds: 99, preferredTimescale: intervalScale))
    assertSnapshot(matching: eventController, as: .image(on: .iPhone8Plus))

    playbackService.playbackPositionHandler = { _ in .end }
    notificationCenter.post(name: .AVPlayerItemDidPlayToEndTime, object: nil, userInfo: nil)
    assertSnapshot(matching: eventController, as: .image(on: .iPhone8Plus))
  }

  func testPlaybackPositionDeregistration() throws {
    let playbackService = PlaybackServiceProtocolMock()
    playbackService.playbackPositionHandler = { _ in .beginning }

    let dependencies = Dependencies()
    dependencies.playbackService = playbackService

    let notificationCenter = NotificationCenter()
    let observer = NSObject()
    let player = Player()

    var addBlock: ((CMTime) -> Void)?
    player.addPeriodicTimeObserverHandler = { _, _, block in
      addBlock = block
      return observer
    }

    var removedObserver: Any?
    player.removeTimeObserverHandler = { observer in
      addBlock = nil
      removedObserver = observer
    }

    let event = try Event.withVideo()
    let eventController = EventController(event: event, dependencies: dependencies, notificationCenter: notificationCenter)

    let eventViewController = EventViewController()
    eventViewController.event = event

    let playerViewController = AVPlayerViewController()
    playerViewController.player = player

    let transitionCoordinator = UIViewControllerTransitionCoordinatorMock()
    eventController.playerViewController(playerViewController, willBeginFullScreenPresentationWithAnimationCoordinator: transitionCoordinator)
    eventController.playerViewController(playerViewController, willEndFullScreenPresentationWithAnimationCoordinator: transitionCoordinator)

    let intervalScale = CMTimeScale(NSEC_PER_SEC)
    addBlock?(CMTime(seconds: 92, preferredTimescale: intervalScale))
    notificationCenter.post(name: .AVPlayerItemDidPlayToEndTime, object: nil, userInfo: nil)
    XCTAssertEqual(removedObserver as? NSObject, observer)
    XCTAssertEqual(playbackService.setPlaybackPositionCallCount, 0)
  }

  func testResumePlayback() throws {
    let playbackService = PlaybackServiceProtocolMock()
    playbackService.playbackPositionHandler = { _ in .at(92) }

    let dependencies = Dependencies()
    dependencies.playbackService = playbackService

    let event = try Event.withVideo()
    let eventController = EventController(event: event, dependencies: dependencies)

    let eventViewController = EventViewController()
    eventViewController.event = event

    let player = Player()

    var seekTime: CMTime?
    player.seekHandler = { time in
      seekTime = time
    }

    let playerViewController = AVPlayerViewController()
    playerViewController.player = player

    let transitionCoordinator = UIViewControllerTransitionCoordinatorMock()
    eventController.playerViewController(playerViewController, willBeginFullScreenPresentationWithAnimationCoordinator: transitionCoordinator)

    let timeScale = CMTimeScale(NSEC_PER_SEC)
    let time = CMTime(seconds: 92, preferredTimescale: timeScale)
    XCTAssertEqual(seekTime, time)
  }

  private final class Player: AVPlayer {
    var addPeriodicTimeObserverHandler: ((CMTime, DispatchQueue?, @escaping (CMTime) -> Void) -> Any)?
    override func addPeriodicTimeObserver(forInterval interval: CMTime, queue: DispatchQueue?, using block: @escaping (CMTime) -> Void) -> Any {
      addPeriodicTimeObserverHandler?(interval, queue, block) as Any
    }

    var removeTimeObserverHandler: ((Any) -> Void)?
    override func removeTimeObserver(_ observer: Any) {
      removeTimeObserverHandler?(observer)
    }

    var seekHandler: ((CMTime) -> Void)?
    override func seek(to time: CMTime) {
      seekHandler?(time)
    }
  }
}

private extension Event {
  static func withVideo() throws -> Event {
    try Event.from(#"{ "room": "D.go", "people": [{ "id": 7738, "name": "Sean DuBois" }], "start": { "minute": 0, "hour": 15 }, "id": 11142, "track": "Go", "title": "Drones, Virtual Reality and Multiplayer NES Games. The fun you can have with Pion WebRTC!", "date": 634304700, "abstract": "<p>In 2020 we saw a huge spike in interest for RTC. Developers worked quickly to\nbuild new tools with the challenge of a socially distanced world. Go has really started\nto make strides in the RTC world with Pion. Easy deploy, great performance, memory safety\nand ability to prototype helped it take on C/C++.</p><p>This talk shows you some basics on WebRTC, then how to use Pion and what you can build with it</p>", "duration": { "minute": 30 }, "links": [ { "name": "Video recording (WebM/VP9)", "url": "https://video.fosdem.org/2021/D.go/gowithoutwires.webm" }, { "name": "Video recording (mp4)", "url": "https://video.fosdem.org/2021/D.go/gowithoutwires.mp4" }, { "name": "Submit feedback", "url": "https://submission.fosdem.org/feedback/11142.php" } ], "attachments": [ { "type": "slides", "url": "https://fosdem.org/2021/schedule/event/gowebrtc/attachments/slides/4583/export/events/attachments/gowebrtc/slides/4583/Slides.pdf", "name": "Slides" } ] }"#)
  }

  static func withLivestream() throws -> Event {
    try Event.from(#"{"room": "D.go", "people": [{ "id": 7738, "name": "Sean DuBois" }], "start": { "minute": 0, "hour": 15 }, "id": 11142, "track": "Go", "title": "Drones, Virtual Reality and Multiplayer NES Games. The fun you can have with Pion WebRTC!", "date": 634304700, "abstract": "<p>In 2020 we saw a huge spike in interest for RTC. Developers worked quickly to\nbuild new tools with the challenge of a socially distanced world. Go has really started\nto make strides in the RTC world with Pion. Easy deploy, great performance, memory safety\nand ability to prototype helped it take on C/C++.</p><p>This talk shows you some basics on WebRTC, then how to use Pion and what you can build with it</p>", "duration": { "minute": 30 }, "links": [{"name": "Submit feedback", "url": "https://submission.fosdem.org/feedback/11142.php"}, {"name": "Live video stream from the room (during event)", "url": "https://live.fosdem.org/watch/dgo"} ], "attachments": [{"type": "slides", "url": "https://fosdem.org/2021/schedule/event/gowebrtc/attachments/slides/4583/export/events/attachments/gowebrtc/slides/4583/Slides.pdf", "name": "Slides"} ] }"#)
  }
}

private final class PlayerViewController: UIViewController, AVPlayerViewControllerProtocol {
  var player: AVPlayer?
  var delegate: AVPlayerViewControllerDelegate?
  var exitsFullScreenWhenPlaybackEnds = false

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .red
  }
}

private final class SafariViewController: UIViewController {
  var url: URL?

  convenience init(url: URL) {
    self.init()
    self.url = url
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .green
  }
}
