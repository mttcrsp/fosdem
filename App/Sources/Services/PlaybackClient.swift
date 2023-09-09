import Foundation

enum PlaybackPosition: Equatable {
  case beginning
  case at(Double)
  case end
}

struct PlaybackClient {
  var watching: () -> Set<Int>
  var watched: () -> Set<Int>

  var setPlaybackPosition: (PlaybackPosition, Int) -> Void
  var playbackPosition: (Int) -> PlaybackPosition

  var addObserver: (@escaping () -> Void) -> NSObjectProtocol
  var removeObserver: (NSObjectProtocol) -> Void
}

extension PlaybackClient {
  init(userDefaults: PlaybackClientDefaults = UserDefaults.standard) {
    let notificationCenter = NotificationCenter()

    func updateWatched(with position: PlaybackPosition, forEventWithIdentifier identifier: Int) -> Bool {
      var didChange = false

      switch position {
      case .beginning, .at:
        let value = watched.remove(identifier)
        didChange = value != nil
      case .end:
        let (inserted, _) = watched.insert(identifier)
        didChange = inserted
      }

      return didChange
    }

    func updateProgress(with position: PlaybackPosition, forEventWithIdentifier identifier: Int) -> Bool {
      var didChange = false

      switch position {
      case .beginning, .end:
        let value = progress.removeValue(forKey: identifier.description)
        didChange = value != nil
      case let .at(seconds):
        let value = progress.updateValue(seconds, forKey: identifier.description)
        didChange = value == nil
      }

      return didChange
    }

    watching = {
      Set(progress.keys.compactMap(Int.init))
    }

    var watched: Set<Int> {
      get { userDefaults.watched }
      set { userDefaults.watched = newValue }
    }

    self.watched = { watched }

    var progress: [String: Double] {
      get { userDefaults.watching }
      set { userDefaults.watching = newValue }
    }

    setPlaybackPosition = { position, identifier in
      var didChangeWatchStatus = false

      if updateWatched(with: position, forEventWithIdentifier: identifier) {
        didChangeWatchStatus = true
      }

      if updateProgress(with: position, forEventWithIdentifier: identifier) {
        didChangeWatchStatus = true
      }

      if didChangeWatchStatus {
        notificationCenter.post(Notification(name: .watchStatusChanged))
      }
    }

    playbackPosition = { identifier in
      if watched.contains(identifier) {
        return .end
      }

      if let seconds = progress[identifier.description] {
        return .at(seconds)
      }

      return .beginning
    }

    addObserver = { handler in
      notificationCenter.addObserver(forName: .watchStatusChanged, object: nil, queue: nil) { _ in
        handler()
      }
    }

    removeObserver = { observer in
      notificationCenter.removeObserver(observer)
    }
  }
}

private extension PlaybackClientDefaults {
  var watched: Set<Int> {
    get {
      let object = value(forKey: .watchedKey)
      let array = object as? [Int] ?? []
      return Set(array)
    }
    set {
      let array = Array(newValue)
      let arrayPlist = NSArray(array: array)
      set(arrayPlist, forKey: .watchedKey)
    }
  }

  var watching: [String: Double] {
    get {
      let object = value(forKey: .watchingKey)
      let dictionary = object as? [String: Double] ?? [:]
      return dictionary
    }
    set {
      set(newValue, forKey: .watchingKey)
    }
  }
}

private extension String {
  static var watchedKey: String { #function }
  static var watchingKey: String { #function }
}

private extension Notification.Name {
  static var watchStatusChanged: Notification.Name { Notification.Name(#function) }
}

/// @mockable
protocol PlaybackClientProtocol {
  var watching: () -> Set<Int> { get }
  var watched: () -> Set<Int> { get }

  var setPlaybackPosition: (PlaybackPosition, Int) -> Void { get }
  var playbackPosition: (Int) -> PlaybackPosition { get }

  var addObserver: (@escaping () -> Void) -> NSObjectProtocol { get }
  var removeObserver: (NSObjectProtocol) -> Void { get }
}

extension PlaybackClient: PlaybackClientProtocol {}

/// @mockable
protocol PlaybackClientDefaults: AnyObject {
  func value(forKey key: String) -> Any?
  func set(_ value: Any?, forKey defaultName: String)
}

extension UserDefaults: PlaybackClientDefaults {}

protocol HasPlaybackClient {
  var playbackClient: PlaybackClientProtocol { get }
}
