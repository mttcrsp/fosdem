import Foundation

struct UpdateService {
  var detectUpdates: (@escaping () -> Void) -> Void
}

extension UpdateService {
  init(networkService: UpdateServiceNetwork, bundle: UpdateServiceBundle = Bundle.main) {
    detectUpdates = { completion in
      guard let bundleIdentifier = bundle.bundleIdentifier else {
        return assertionFailure("Failed to acquire bundle identifier from bundle \(bundle)")
      }

      guard let bundleShortVersion = bundle.bundleShortVersion else {
        return assertionFailure("Failed to acquire short bundle version from bundle \(bundle)")
      }

      networkService.getFosdemApp { result in
        guard case let .success(response) = result else { return }

        guard let result = response.results.first(where: { result in result.bundleIdentifier == bundleIdentifier }) else {
          return assertionFailure("AppStore search request did not return any application with identifier \(bundleIdentifier)")
        }

        if result.version.compare(bundleShortVersion, options: .numeric) == .orderedDescending {
          completion()
        }
      }
    }
  }
}

/// @mockable
protocol UpdateServiceProtocol {
  var detectUpdates: (@escaping () -> Void) -> Void { get }
}

extension UpdateService: UpdateServiceProtocol {}

/// @mockable
protocol UpdateServiceBundle {
  var bundleIdentifier: String? { get }
  var bundleShortVersion: String? { get }
}

extension Bundle: UpdateServiceBundle {}

/// @mockable
protocol UpdateServiceNetwork {
  var getFosdemApp: (@escaping (Result<AppStoreSearchResponse, Error>) -> Void) -> Void { get }
}

extension NetworkService: UpdateServiceNetwork {}

protocol HasUpdateService {
  var updateService: UpdateServiceProtocol { get }
}
