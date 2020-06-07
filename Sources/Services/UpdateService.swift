import Foundation

protocol UpdateServiceNetwork {
  @discardableResult
  func perform(_ request: AppStoreSearchRequest, completion: @escaping (Result<AppStoreSearchResponse, Error>) -> Void) -> NetworkServiceTask
}

protocol UpdateServiceBundle {
  var bundleIdentifier: String? { get }
  var bundleShortVersion: String? { get }
}

protocol UpdateServiceDelegate: AnyObject {
  func updateServiceDidDetectUpdate(_ updateService: UpdateService)
}

final class UpdateService {
  weak var delegate: UpdateServiceDelegate?

  private let bundle: UpdateServiceBundle
  private let networkService: UpdateServiceNetwork

  init(networkService: UpdateServiceNetwork, bundle: UpdateServiceBundle = Bundle.main) {
    self.networkService = networkService
    self.bundle = bundle
  }

  func detectUpdates() {
    guard let bundleIdentifier = bundle.bundleIdentifier else {
      return assertionFailure("Failed to acquire bundle identifier from bundle \(bundle)")
    }

    guard let bundleShortVersion = bundle.bundleShortVersion else {
      return assertionFailure("Failed to acquire short bundle version from bundle \(bundle)")
    }

    let request = AppStoreSearchRequest()
    networkService.perform(request) { [weak self] result in
      guard let self = self, case let .success(response) = result else { return }

      guard let result = response.results.first(where: { result in result.bundleIdentifier == bundleIdentifier }) else {
        // The following assertion cannot be enable before the first
        // version of the app is released to the store.
        //
        // return assertionFailure("AppStore search request did not return any application with identifier \(bundleIdentifier)")
        return
      }

      if result.version.compare(bundleShortVersion, options: .numeric) == .orderedDescending {
        self.delegate?.updateServiceDidDetectUpdate(self)
      }
    }
  }
}

extension Bundle: UpdateServiceBundle {}

extension NetworkService: UpdateServiceNetwork {}
