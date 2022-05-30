import Foundation

final class FavoritesService {
  private let userDefaults: FavoritesServiceDefaults
  private let notificationCenter = NotificationCenter()

  init(userDefaults: FavoritesServiceDefaults = UserDefaults.standard) {
    self.userDefaults = userDefaults
  }

  var tracksIdentifiers: Set<String> {
    get { userDefaults.tracksIdentifiers }
    set { userDefaults.tracksIdentifiers = newValue }
  }

  var eventsIdentifiers: Set<Int> {
    get { userDefaults.eventsIdentifiers }
    set { userDefaults.eventsIdentifiers = newValue }
  }

  func addObserverForTracks(_ handler: @escaping (String) -> Void) -> NSObjectProtocol {
    notificationCenter.addObserver(forName: .favoriteTracksDidChange, object: nil, queue: nil, using: { notification in
      if let identifier = notification.userInfo?["identifier"] as? String {
        handler(identifier)
      }
    })
  }

  func addObserverForEvents(_ handler: @escaping (Int) -> Void) -> NSObjectProtocol {
    notificationCenter.addObserver(forName: .favoriteEventsDidChange, object: nil, queue: nil, using: { notification in
      if let identifier = notification.userInfo?["identifier"] as? Int {
        handler(identifier)
      }
    })
  }

  func removeObserver(_ observer: NSObjectProtocol) {
    notificationCenter.removeObserver(observer)
  }

  func addTrack(withIdentifier identifier: String) {
    let (inserted, _) = tracksIdentifiers.insert(identifier)
    if inserted {
      let userInfo = ["identifier": identifier]
      let notification = Notification(name: .favoriteTracksDidChange, userInfo: userInfo)
      notificationCenter.post(notification)
    }
  }

  func removeTrack(withIdentifier identifier: String) {
    if let _ = tracksIdentifiers.remove(identifier) {
      let userInfo = ["identifier": identifier]
      let notification = Notification(name: .favoriteTracksDidChange, userInfo: userInfo)
      notificationCenter.post(notification)
    }
  }

  func addEvent(withIdentifier identifier: Int) {
    let (inserted, _) = eventsIdentifiers.insert(identifier)
    if inserted {
      let userInfo = ["identifier": identifier]
      let notification = Notification(name: .favoriteEventsDidChange, userInfo: userInfo)
      notificationCenter.post(notification)
    }
  }

  func removeEvent(withIdentifier identifier: Int) {
    if let _ = eventsIdentifiers.remove(identifier) {
      let userInfo = ["identifier": identifier]
      let notification = Notification(name: .favoriteEventsDidChange, userInfo: userInfo)
      notificationCenter.post(notification)
    }
  }

  func removeAllTracksAndEvents() {
    for identifier in tracksIdentifiers {
      removeTrack(withIdentifier: identifier)
    }

    for identifier in eventsIdentifiers {
      removeEvent(withIdentifier: identifier)
    }
  }
}

private extension FavoritesServiceDefaults {
  var tracksIdentifiers: Set<String> {
    get {
      let object = value(forKey: .favoriteTracksKey)
      let array = object as? [String] ?? []
      return Set(array)
    }
    set {
      let array = Array(newValue)
      let arrayPlist = NSArray(array: array)
      set(arrayPlist, forKey: .favoriteTracksKey)
    }
  }

  var eventsIdentifiers: Set<Int> {
    get {
      let object = value(forKey: .favoriteEventsKey)
      let array = object as? [Int] ?? []
      return Set(array)
    }
    set {
      let array = Array(newValue)
      let arrayPlist = NSArray(array: array)
      set(arrayPlist, forKey: .favoriteEventsKey)
    }
  }
}

extension FavoritesService {
  func canFavorite(_ event: Event) -> Bool {
    !eventsIdentifiers.contains(event.id)
  }

  func toggleFavorite(_ event: Event) {
    if canFavorite(event) {
      addEvent(withIdentifier: event.id)
    } else {
      removeEvent(withIdentifier: event.id)
    }
  }

  func canFavorite(_ track: Track) -> Bool {
    !tracksIdentifiers.contains(track.name)
  }

  func toggleFavorite(_ track: Track) {
    if canFavorite(track) {
      addTrack(withIdentifier: track.name)
    } else {
      removeTrack(withIdentifier: track.name)
    }
  }
}

private extension String {
  static var favoriteTracksKey: String { #function }
  static var favoriteEventsKey: String { #function }
}

private extension Notification.Name {
  static var favoriteTracksDidChange: Notification.Name { Notification.Name(#function) }
  static var favoriteEventsDidChange: Notification.Name { Notification.Name(#function) }
}

/// @mockable
protocol FavoritesServiceProtocol {
  var tracksIdentifiers: Set<String> { get set }
  var eventsIdentifiers: Set<Int> { get set }

  func addObserverForTracks(_ handler: @escaping (String) -> Void) -> NSObjectProtocol
  func addObserverForEvents(_ handler: @escaping (Int) -> Void) -> NSObjectProtocol
  func removeObserver(_ observer: NSObjectProtocol)

  func addTrack(withIdentifier identifier: String)
  func removeTrack(withIdentifier identifier: String)

  func addEvent(withIdentifier identifier: Int)
  func removeEvent(withIdentifier identifier: Int)

  func removeAllTracksAndEvents()

  func canFavorite(_ event: Event) -> Bool
  func canFavorite(_ track: Track) -> Bool
  func toggleFavorite(_ event: Event)
  func toggleFavorite(_ track: Track)
}

extension FavoritesService: FavoritesServiceProtocol {}

/// @mockable
protocol FavoritesServiceDefaults: AnyObject {
  func value(forKey key: String) -> Any?
  func set(_ value: Any?, forKey defaultName: String)
}

extension UserDefaults: FavoritesServiceDefaults {}

protocol HasFavoritesService {
  var favoritesService: FavoritesServiceProtocol { get }
}
