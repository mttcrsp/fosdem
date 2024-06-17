protocol Favoriting {
  var favoritesService: FavoritesServiceProtocol { get }
}

extension Favoriting {
  func canFavorite(_ event: Event) -> Bool {
    !favoritesService.contains(event)
  }

  func didFavorite(_ event: Event) {
    favoritesService.addEvent(withIdentifier: event.id)
  }

  func didUnfavorite(_ event: Event) {
    favoritesService.removeEvent(withIdentifier: event.id)
  }
}

extension Favoriting {
  func canFavorite(_ track: Track) -> Bool {
    !favoritesService.contains(track)
  }

  func didFavorite(_ track: Track) {
    favoritesService.addTrack(withIdentifier: track.name)
  }

  func didUnfavorite(_ track: Track) {
    favoritesService.removeTrack(withIdentifier: track.name)
  }
}
