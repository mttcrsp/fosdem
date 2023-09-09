import Foundation

struct UpdateClient {
  var detectUpdates: (@escaping () -> Void) -> Void
}

extension UpdateClient {
  init(networkClient: UpdateClientNetwork, bundle: UpdateClientBundle = Bundle.main) {
    detectUpdates = { completion in
      guard let bundleIdentifier = bundle.bundleIdentifier else {
        return assertionFailure("Failed to acquire bundle identifier from bundle \(bundle)")
      }

      guard let bundleShortVersion = bundle.bundleShortVersion else {
        return assertionFailure("Failed to acquire short bundle version from bundle \(bundle)")
      }

      networkClient.getFosdemApp { result in
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
protocol UpdateClientProtocol {
  var detectUpdates: (@escaping () -> Void) -> Void { get }
}

extension UpdateClient: UpdateClientProtocol {}

/// @mockable
protocol UpdateClientBundle {
  var bundleIdentifier: String? { get }
  var bundleShortVersion: String? { get }
}

extension Bundle: UpdateClientBundle {}

/// @mockable
protocol UpdateClientNetwork {
  var getFosdemApp: (@escaping (Result<AppStoreSearchResponse, Error>) -> Void) -> Void { get }
}

extension NetworkClient: UpdateClientNetwork {}

protocol HasUpdateClient {
  var updateClient: UpdateClientProtocol { get }
}
