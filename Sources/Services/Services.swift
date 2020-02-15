final class Services {
    private(set) lazy var defaultsService = DefaultsService()
    private(set) lazy var favoritesService = FavoritesService(defaultsService: defaultsService)
}
