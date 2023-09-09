import Foundation

struct FavoritesService {
  var eventsIdentifiers: () -> Set<Int>
  var tracksIdentifiers: () -> Set<String>

  var addEvent: (Int) -> Void
  var addTrack: (String) -> Void
  var removeEvent: (Int) -> Void
  var removeTrack: (String) -> Void
  var removeAllTracksAndEvents: () -> Void

  var addObserverForEvents: (@escaping () -> Void) -> NSObjectProtocol
  var addObserverForTracks: (@escaping () -> Void) -> NSObjectProtocol
  var removeObserver: (NSObjectProtocol) -> Void

  var startMonitoring: () -> Void
  var stopMonitoring: () -> Void

  var migrate: () -> Void
}

extension FavoritesService {
  init(fosdemYear _: Year, preferencesService: PreferencesServiceProtocol, ubiquitousPreferencesService: UbiquitousPreferencesServiceProtocol, timeService: TimeServiceProtocol, userDefaults: FavoritesServiceDefaults = UserDefaults.standard) {
    let notificationCenter = NotificationCenter()
    var ubiquitousObserver: NSObjectProtocol?

    let year = YearsService.current
    let favoriteEventsKey = "com.mttcrsp.ansia.FavoritesClient.favoriteEvents"
    let favoriteTracksKey = "com.mttcrsp.ansia.FavoritesClient.favoriteTracks"
    let favoriteEventsDidChange = Notification.Name("com.mttcrsp.ansia.FavoritesClient.favoriteEventsDidChange")
    let favoriteTracksDidChange = Notification.Name("com.mttcrsp.ansia.FavoritesClient.favoriteTracksDidChange")
    let notificationNameForKey: [String: Notification.Name] = [
      favoriteEventsKey: favoriteEventsDidChange,
      favoriteTracksKey: favoriteTracksDidChange,
    ]

    let value: (String) -> Any? = { key in
      if let dictionary = preferencesService.value(key) as? [String: Any] {
        dictionary["value"]
      } else {
        nil
      }
    }

    let set: (Any?, String) -> Void = { value, key in
      let dictionary = ["value": value as Any, "updatedAt": timeService.now()]
      preferencesService.set(dictionary, key)
      ubiquitousPreferencesService.set(dictionary, key)
    }

    let policy: (FavoritesMerge) -> FavoritesMergePolicy = { merge in
      if merge.remote == nil, merge.local == nil {
        return .ignore
      }

      guard let remote = merge.remote,
            let remoteDictionary = remote.value as? [String: Any],
            let remoteYear = remoteDictionary["year"] as? Int,
            remoteYear == year
      else {
        return .updateRemote
      }

      guard let local = merge.local,
            let localDictionary = local.value as? [String: Any],
            let localYear = localDictionary["year"] as? Int,
            localYear == year
      else {
        return .updateLocal
      }

      if remote.updatedAt == local.updatedAt {
        return .ignore
      } else if remote.updatedAt > local.updatedAt {
        return .updateLocal
      } else {
        return .updateRemote
      }
    }

    let syncValue: (String) -> Void = { key in
      guard let notificationName = notificationNameForKey[key] else { return }
      let remoteValue = ubiquitousPreferencesService.value(key)
      let remote = FavoritesMergeValue(value: remoteValue as Any)
      let localValue = preferencesService.value(key)
      let local = FavoritesMergeValue(value: localValue as Any)
      let merge = FavoritesMerge(local: local, remote: remote)
      switch policy(merge) {
      case .ignore:
        break
      case .updateRemote:
        ubiquitousPreferencesService.set(localValue, key)
      case .updateLocal:
        preferencesService.set(remoteValue, key)
        notificationCenter.post(.init(name: notificationName))
      }
    }

    var eventsIdentifiers: Set<Int> = [] {
      didSet { set(["year": year, "identifiers": Array(eventsIdentifiers)], favoriteEventsKey) }
    }

    if let dictionary = value(favoriteEventsKey) as? [String: Any] {
      if let array = dictionary["identifiers"] as? [Int] {
        if dictionary["year"] as? Year == year {
          eventsIdentifiers = Set(array)
        }
      }
    }

    var tracksIdentifiers: Set<String> = [] {
      didSet { set(["year": year, "identifiers": Array(tracksIdentifiers)], favoriteTracksKey) }
    }

    if let dictionary = value(favoriteTracksKey) as? [String: Any] {
      if let array = dictionary["identifiers"] as? [String] {
        if dictionary["year"] as? Year == year {
          tracksIdentifiers = Set(array)
        }
      }
    }

    self.eventsIdentifiers = {
      eventsIdentifiers
    }

    self.tracksIdentifiers = {
      tracksIdentifiers
    }

    addEvent = { identifier in
      let (inserted, _) = eventsIdentifiers.insert(identifier)
      if inserted {
        notificationCenter.post(.init(name: favoriteEventsDidChange))
      }
    }

    addTrack = { identifier in
      let (inserted, _) = tracksIdentifiers.insert(identifier)
      if inserted {
        notificationCenter.post(.init(name: favoriteTracksDidChange))
      }
    }

    removeEvent = { identifier in
      if let _ = eventsIdentifiers.remove(identifier) {
        notificationCenter.post(.init(name: favoriteEventsDidChange))
      }
    }

    removeTrack = { identifier in
      if let _ = tracksIdentifiers.remove(identifier) {
        notificationCenter.post(.init(name: favoriteTracksDidChange))
      }
    }

    removeAllTracksAndEvents = {
      eventsIdentifiers.removeAll()
      tracksIdentifiers.removeAll()
      notificationCenter.post(.init(name: favoriteEventsDidChange))
      notificationCenter.post(.init(name: favoriteTracksDidChange))
    }

    addObserverForEvents = { handler in
      notificationCenter.addObserver(forName: .favoriteEventsDidChange, object: nil, queue: .main) { _ in
        handler()
      }
    }

    addObserverForTracks = { handler in
      notificationCenter.addObserver(forName: .favoriteTracksDidChange, object: nil, queue: .main) { _ in
        handler()
      }
    }

    removeObserver = { observer in
      notificationCenter.removeObserver(observer)
    }

    startMonitoring = {
      guard ubiquitousObserver == nil else {
        assertionFailure("Attempted to start monitoring on already active favorites client")
        return
      }

      for key in notificationNameForKey.keys {
        syncValue(key)
      }

      ubiquitousObserver = ubiquitousPreferencesService.addObserver { key in
        syncValue(key)
      }
    }

    stopMonitoring = {
      guard let observer = ubiquitousObserver else {
        assertionFailure("Attempted to stop monitoring on inactive favorites client")
        return
      }

      ubiquitousPreferencesService.removeObserver(observer)
    }

    migrate = {
      let favoriteEventsKey = "favoriteEventsKey"
      let favoriteTracksKey = "favoriteTracksKey"

      if let identifiers = userDefaults.value(forKey: favoriteEventsKey) as? [Int] {
        eventsIdentifiers = Set(identifiers)
        userDefaults.removeObject(forKey: favoriteEventsKey)
      }

      if let identifiers = userDefaults.value(forKey: favoriteTracksKey) as? [String] {
        tracksIdentifiers = Set(identifiers)
        userDefaults.removeObject(forKey: favoriteTracksKey)
      }
    }
  }
}

private enum FavoritesMergePolicy {
  case ignore
  case updateLocal
  case updateRemote
}

private struct FavoritesMerge {
  let local: FavoritesMergeValue?
  let remote: FavoritesMergeValue?
}

private struct FavoritesMergeValue {
  let value: Any?
  let updatedAt: Date
}

private extension FavoritesMergeValue {
  init?(value: Any) {
    if let dictionary = value as? [String: Any], let updatedAt = dictionary["updatedAt"] as? Date {
      self.init(value: dictionary["value"], updatedAt: updatedAt)
    } else {
      return nil
    }
  }
}

private extension String {
  static let favoriteEventsKey = "com.mttcrsp.ansia.FavoritesService.favoriteEvents"
  static let favoriteTracksKey = "com.mttcrsp.ansia.FavoritesService.favoriteTracks"
}

private extension Notification.Name {
  static var favoriteEventsDidChange = Notification.Name("com.mttcrsp.ansia.FavoritesService.favoriteEventsDidChange")
  static var favoriteTracksDidChange = Notification.Name("com.mttcrsp.ansia.FavoritesService.favoriteTracksDidChange")
}

/// @mockable
protocol FavoritesServiceProtocol {
  var eventsIdentifiers: () -> Set<Int> { get }
  var tracksIdentifiers: () -> Set<String> { get }

  var addEvent: (Int) -> Void { get }
  var addTrack: (String) -> Void { get }
  var removeEvent: (Int) -> Void { get }
  var removeTrack: (String) -> Void { get }
  var removeAllTracksAndEvents: () -> Void { get }

  var addObserverForEvents: (@escaping () -> Void) -> NSObjectProtocol { get }
  var addObserverForTracks: (@escaping () -> Void) -> NSObjectProtocol { get }
  var removeObserver: (NSObjectProtocol) -> Void { get }

  var startMonitoring: () -> Void { get }
  var stopMonitoring: () -> Void { get }

  var migrate: () -> Void { get }
}

extension FavoritesService: FavoritesServiceProtocol {}

extension FavoritesServiceProtocol {
  func contains(_ event: Event) -> Bool {
    eventsIdentifiers().contains(event.id)
  }

  func contains(_ track: Track) -> Bool {
    tracksIdentifiers().contains(track.name)
  }
}

/// @mockable
protocol FavoritesServiceDefaults: AnyObject {
  func value(forKey key: String) -> Any?
  func removeObject(forKey defaultName: String)
}

extension UserDefaults: FavoritesServiceDefaults {}

protocol HasFavoritesService {
  var favoritesService: FavoritesServiceProtocol { get }
}
