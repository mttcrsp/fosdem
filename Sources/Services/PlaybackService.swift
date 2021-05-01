import Foundation

enum PlaybackPosition: Equatable {
  case beginning
  case at(Double)
  case end
}

final class PlaybackService {
  var watching: Set<Int> {
    Set(progress.keys.compactMap(Int.init))
  }

  private(set) var watched: Set<Int> {
    get { userDefaults.watched }
    set { userDefaults.watched = newValue }
  }

  private var progress: [String: Double] {
    get { userDefaults.watching }
    set { userDefaults.watching = newValue }
  }

  private let userDefaults: PlaybackServiceDefaults
  private let notificationCenter = NotificationCenter()

  init(userDefaults: PlaybackServiceDefaults = UserDefaults.standard) {
    self.userDefaults = userDefaults
  }

  func setPlaybackPosition(_ position: PlaybackPosition, forEventWithIdentifier identifier: Int) {
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

  func playbackPosition(forEventWithIdentifier identifier: Int) -> PlaybackPosition {
    if watched.contains(identifier) {
      return .end
    }

    if let seconds = progress[identifier.description] {
      return .at(seconds)
    }

    return .beginning
  }

  func addObserver(_ handler: @escaping () -> Void) -> NSObjectProtocol {
    notificationCenter.addObserver(forName: .watchStatusChanged, object: nil, queue: nil) { _ in
      handler()
    }
  }

  func removeObserver(_ observer: NSObjectProtocol) {
    notificationCenter.removeObserver(observer)
  }

  private func updateWatched(with position: PlaybackPosition, forEventWithIdentifier identifier: Int) -> Bool {
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

  private func updateProgress(with position: PlaybackPosition, forEventWithIdentifier identifier: Int) -> Bool {
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
}

private extension PlaybackServiceDefaults {
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

protocol PlaybackServiceProtocol {
  var watching: Set<Int> { get }
  var watched: Set<Int> { get }

  func setPlaybackPosition(_ position: PlaybackPosition, forEventWithIdentifier identifier: Int)
  func playbackPosition(forEventWithIdentifier identifier: Int) -> PlaybackPosition

  func addObserver(_ handler: @escaping () -> Void) -> NSObjectProtocol
  func removeObserver(_ observer: NSObjectProtocol)
}

extension PlaybackService: PlaybackServiceProtocol {}

/// @mockable
protocol PlaybackServiceDefaults: AnyObject {
  func value(forKey key: String) -> Any?
  func set(_ value: Any?, forKey defaultName: String)
}

extension UserDefaults: PlaybackServiceDefaults {}
