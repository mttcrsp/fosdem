final class Services {
    private(set) lazy var defaultsService = DefaultsService()
    private(set) lazy var favoritesService = FavoritesService(defaultsService: defaultsService)
}

protocol HasDefaultsService {
    var defaultsService: DefaultsService { get }
}

protocol HasFavoritesService {
    var favoritesService: FavoritesService { get }
}

extension Services: HasDefaultsService {}
extension Services: HasFavoritesService {}
