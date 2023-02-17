import Foundation

final class FavoritesService {
  private let notificationCenter = NotificationCenter()
  private let preferencesService: PreferencesServiceProtocol
  private let ubiquitousPreferencesService: UbiquitousPreferencesServiceProtocol
  private var ubiquitousObserver: NSObjectProtocol?
  private let timeService: TimeServiceProtocol
  private let fosdemYear: Year

  init(fosdemYear: Year, preferencesService: PreferencesServiceProtocol, ubiquitousPreferencesService: UbiquitousPreferencesServiceProtocol, timeService: TimeServiceProtocol) {
    self.fosdemYear = fosdemYear
    self.timeService = timeService
    self.preferencesService = preferencesService
    self.ubiquitousPreferencesService = ubiquitousPreferencesService
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
    let fosdemYear = fosdemYear
    let policy: (FavoritesMerge) -> FavoritesMergePolicy = { merge in
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

      if remote.updatedAt > local.updatedAt {
        return .updateLocal
      } else {
        return .updateRemote
      }
    }

    internalStartMonitoringRemote(withMergePolicies: [
      .favoriteEventsKey: policy,
      .favoriteTracksKey: policy,
    ])
  }

  func stopMonitoring() {
    internalStopMonitoringRemote()
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

private extension FavoritesService {
  func value(forKey key: String) -> Any? {
    if let dictionary = preferencesService.value(forKey: key) as? [String: Any] {
      return dictionary["value"]
    } else {
      return nil
    }
  }

  func set(_ value: Any?, forKey key: String) {
    let dictionary = ["value": value as Any, "updatedAt": timeService.now]
    preferencesService.set(dictionary, forKey: key)
    ubiquitousPreferencesService.set(dictionary, forKey: key)
  }

  func removeValue(forKey key: String) {
    preferencesService.removeValue(forKey: key)
    ubiquitousPreferencesService.removeValue(forKey: key)
  }

  func internalStartMonitoringRemote(withMergePolicies policies: [String: (FavoritesMerge) -> FavoritesMergePolicy]) {
    guard ubiquitousObserver == nil else {
      return assertionFailure("Attempted to start monitoring on already active favorites service \(self)")
    }

    ubiquitousObserver = ubiquitousPreferencesService.addObserver { [weak self] key in
      self?.didChangeRemoveValue(forKey: key, with: policies)
    }
  }

  func internalStopMonitoringRemote() {
    guard let observer = ubiquitousObserver else {
      return assertionFailure("Attempted to stop monitoring on inactive favorites service \(self)")
    }

    ubiquitousPreferencesService.removeObserver(observer)
  }

  private func didChangeRemoveValue(forKey key: String, with policies: [String: (FavoritesMerge) -> FavoritesMergePolicy]) {
    guard let policy = policies[key] else { return }

    let remoteValue = ubiquitousPreferencesService.value(forKey: key)
    let remote = FavoritesMergeValue(value: remoteValue as Any)
    let localValue = preferencesService.value(forKey: key)
    let local = FavoritesMergeValue(value: localValue as Any)
    let merge = FavoritesMerge(local: local, remote: remote)
    switch policy(merge) {
    case .updateRemote:
      ubiquitousPreferencesService.set(localValue, forKey: key)
    case .updateLocal:
      preferencesService.set(remoteValue, forKey: key)

      switch key {
      case .favoriteEventsKey:
        notificationCenter.post(.init(name: .favoriteEventsDidChange))
      case .favoriteTracksKey:
        notificationCenter.post(.init(name: .favoriteTracksDidChange))
      default:
        break
      }
    }
  }
}

private enum FavoritesMergePolicy {
  case updateLocal, updateRemote
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
}

protocol HasFavoritesService {
  var favoritesService: FavoritesServiceProtocol { get }
}
