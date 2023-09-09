import Foundation

final class FavoritesService {
  private let notificationCenter = NotificationCenter()
  private let preferencesService: PreferencesServiceProtocol
  private let ubiquitousPreferencesService: UbiquitousPreferencesServiceProtocol
  private var ubiquitousObserver: NSObjectProtocol?
  private let timeService: TimeServiceProtocol
  private let fosdemYear: Year
  private let userDefaults: FavoritesServiceDefaults

  init(fosdemYear: Year, preferencesService: PreferencesServiceProtocol, ubiquitousPreferencesService: UbiquitousPreferencesServiceProtocol, timeService: TimeServiceProtocol, userDefaults: FavoritesServiceDefaults = UserDefaults.standard) {
    self.fosdemYear = fosdemYear
    self.timeService = timeService
    self.preferencesService = preferencesService
    self.ubiquitousPreferencesService = ubiquitousPreferencesService
    self.userDefaults = userDefaults
  }

  private(set) var eventsIdentifiers: Set<Int> {
    get {
      if let dictionary = value(forKey: .favoriteEventsKey) as? [String: Any], let array = dictionary["identifiers"] as? [Int], dictionary["year"] as? Year == fosdemYear {
        return Set(array)
      } else {
        return []
      }
    }
    set {
      let value: [String: Any] = ["year": fosdemYear, "identifiers": Array(newValue)]
      set(value, forKey: .favoriteEventsKey)
    }
  }

  private(set) var tracksIdentifiers: Set<String> {
    get {
      if let dictionary = value(forKey: .favoriteTracksKey) as? [String: Any], let array = dictionary["identifiers"] as? [String], dictionary["year"] as? Year == fosdemYear {
        return Set(array)
      } else {
        return []
      }
    }
    set {
      let value: [String: Any] = ["year": fosdemYear, "identifiers": Array(newValue)]
      set(value, forKey: .favoriteTracksKey)
    }
  }

  func addObserverForEvents(_ handler: @escaping () -> Void) -> NSObjectProtocol {
    notificationCenter.addObserver(forName: .favoriteEventsDidChange, object: nil, queue: nil) { _ in
      handler()
    }
  }

  func addObserverForTracks(_ handler: @escaping () -> Void) -> NSObjectProtocol {
    notificationCenter.addObserver(forName: .favoriteTracksDidChange, object: nil, queue: .main) { _ in
      handler()
    }
  }

  func removeObserver(_ observer: NSObjectProtocol) {
    notificationCenter.removeObserver(observer)
  }

  func startMonitoring() {
    guard ubiquitousObserver == nil else {
      return assertionFailure("Attempted to start monitoring on already active favorites service \(self)")
    }

    for key in notificationNameForKey.keys {
      syncValue(forKey: key)
    }

    ubiquitousObserver = ubiquitousPreferencesService.addObserver { [weak self] key in
      self?.syncValue(forKey: key)
    }
  }

  func stopMonitoring() {
    guard let observer = ubiquitousObserver else {
      return assertionFailure("Attempted to stop monitoring on inactive favorites service \(self)")
    }

    ubiquitousPreferencesService.removeObserver(observer)
  }
}

extension FavoritesService {
  func addEvent(withIdentifier identifier: Int) {
    let (inserted, _) = eventsIdentifiers.insert(identifier)
    if inserted {
      notificationCenter.post(.init(name: .favoriteEventsDidChange))
    }
  }

  func addTrack(withIdentifier identifier: String) {
    let (inserted, _) = tracksIdentifiers.insert(identifier)
    if inserted {
      notificationCenter.post(.init(name: .favoriteTracksDidChange))
    }
  }

  func removeEvent(withIdentifier identifier: Int) {
    if let _ = eventsIdentifiers.remove(identifier) {
      notificationCenter.post(.init(name: .favoriteEventsDidChange))
    }
  }

  func removeTrack(withIdentifier identifier: String) {
    if let _ = tracksIdentifiers.remove(identifier) {
      notificationCenter.post(.init(name: .favoriteTracksDidChange))
    }
  }

  func removeAllTracksAndEvents() {
    eventsIdentifiers.removeAll()
    tracksIdentifiers.removeAll()
    notificationCenter.post(.init(name: .favoriteEventsDidChange))
    notificationCenter.post(.init(name: .favoriteTracksDidChange))
  }

  func contains(_ event: Event) -> Bool {
    eventsIdentifiers.contains(event.id)
  }

  func contains(_ track: Track) -> Bool {
    tracksIdentifiers.contains(track.name)
  }
}

extension FavoritesService {
  func migrate() {
    let favoriteEventsKey = "favoriteEventsKey"
    let favoriteTracksKey = "favoriteTracksKey"

    if let eventsIdentifiers = userDefaults.value(forKey: favoriteEventsKey) as? [Int] {
      self.eventsIdentifiers = Set(eventsIdentifiers)
      userDefaults.removeObject(forKey: favoriteEventsKey)
    }

    if let tracksIdentifiers = userDefaults.value(forKey: favoriteTracksKey) as? [String] {
      self.tracksIdentifiers = Set(tracksIdentifiers)
      userDefaults.removeObject(forKey: favoriteTracksKey)
    }
  }
}

private extension FavoritesService {
  func value(forKey key: String) -> Any? {
    if let dictionary = preferencesService.value(key) as? [String: Any] {
      return dictionary["value"]
    } else {
      return nil
    }
  }

  func set(_ value: Any?, forKey key: String) {
    let dictionary = ["value": value as Any, "updatedAt": timeService.now]
    preferencesService.set(dictionary, key)
    ubiquitousPreferencesService.set(dictionary, key)
  }

  func removeValue(forKey key: String) {
    preferencesService.removeValue(key)
    ubiquitousPreferencesService.removeValue(key)
  }

  private func syncValue(forKey key: String) {
    guard let notificationName = notificationNameForKey[key] else { return }
    let remoteValue = ubiquitousPreferencesService.value(key)
    let remote = FavoritesMergeValue(value: remoteValue as Any)
    let localValue = preferencesService.value(key)
    let local = FavoritesMergeValue(value: localValue as Any)
    let merge = FavoritesMerge(local: local, remote: remote)
    switch policy(for: merge) {
    case .ignore:
      break
    case .updateRemote:
      ubiquitousPreferencesService.set(localValue, key)
    case .updateLocal:
      preferencesService.set(remoteValue, key)
      notificationCenter.post(.init(name: notificationName))
    }
  }

  private func policy(for merge: FavoritesMerge) -> FavoritesMergePolicy {
    if merge.remote == nil, merge.local == nil {
      return .ignore
    }

    guard let remote = merge.remote,
          let remoteDictionary = remote.value as? [String: Any],
          let remoteYear = remoteDictionary["year"] as? Int,
          remoteYear == fosdemYear
    else {
      return .updateRemote
    }

    guard let local = merge.local,
          let localDictionary = local.value as? [String: Any],
          let localYear = localDictionary["year"] as? Int,
          localYear == fosdemYear
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

  private var notificationNameForKey: [String: Notification.Name] {
    [
      .favoriteEventsKey: .favoriteEventsDidChange,
      .favoriteTracksKey: .favoriteTracksDidChange,
    ]
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

extension FavoritesService: FavoritesServiceProtocol {}

/// @mockable
protocol FavoritesServiceProtocol {
  var eventsIdentifiers: Set<Int> { get }
  var tracksIdentifiers: Set<String> { get }

  func addObserverForEvents(_ handler: @escaping () -> Void) -> NSObjectProtocol
  func addObserverForTracks(_ handler: @escaping () -> Void) -> NSObjectProtocol
  func removeObserver(_ observer: NSObjectProtocol)

  func addEvent(withIdentifier identifier: Int)
  func addTrack(withIdentifier identifier: String)

  func removeEvent(withIdentifier identifier: Int)
  func removeTrack(withIdentifier identifier: String)
  func removeAllTracksAndEvents()

  func contains(_ event: Event) -> Bool
  func contains(_ track: Track) -> Bool

  func startMonitoring()
  func stopMonitoring()

  func migrate()
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
