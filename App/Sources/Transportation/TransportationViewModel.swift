import Combine
import Foundation

final class TransportationViewModel {
  typealias Dependencies = HasInfoService & HasOpenService
  private let dependencies: Dependencies
  let didOpenURL = PassthroughSubject<Void, Never>()
  let didLoadInfo = PassthroughSubject<Result<(Info, TransportationItem, NSAttributedString), Error>, Never>()

  init(dependencies: Dependencies) {
    self.dependencies = dependencies
  }

  func didSelect(_ item: TransportationItem) {
    switch item {
    case .appleMaps:
      openURL(.ulbAppleMaps)
    case .googleMaps:
      openURL(.ulbGoogleMaps)
    case .bus, .car, .taxi, .plane, .train, .shuttle:
      guard let info = item.info else {
        return assertionFailure("Failed to determine info model for transportation item '\(item)'")
      }

      dependencies.infoService.loadAttributedText(for: info) { [weak self] result in
        switch result {
        case let .failure(error):
          self?.didLoadInfo.send(.failure(error))
        case let .success(attributedText):
          self?.didLoadInfo.send(.success((info, item, attributedText)))
        }
      }
    }
  }
}

private extension TransportationViewModel {
  func openURL(_ url: URL) {
    dependencies.openService.open(url) { [weak self] _ in
      self?.didOpenURL.send()
    }
  }
}

private extension TransportationItem {
  var info: Info? {
    switch self {
    case .bus: .bus
    case .car: .car
    case .taxi: .taxi
    case .plane: .plane
    case .train: .train
    case .shuttle: .shuttle
    case .appleMaps, .googleMaps: nil
    }
  }
}

private extension URL {
  static let ulbAppleMaps = URL(string: "https://maps.apple.com/?address=Avenue%20Franklin%20Roosevelt%2050,%201050%20Brussels,%20Belgium&auid=2450730505287536200&ll=50.812050,4.382236&lsp=9902&q=Universit%C3%A9%20Libre%20de%20Bruxelles&_ext=ChgKBAgEEFcKBAgFEAMKBAgGEBkKBAgKEAESJCkjtQWwbFxJQDFgm0ZDufUQQDkZviUmcHNJQEGgZLl8GBkSQA%3D%3D")!
  static let ulbGoogleMaps = URL(string: "https://www.google.com/maps/place/Universit%C3%A9+Libre+de+Bruxelles/@50.8132068,4.3800335,17z/data=!3m1!4b1!4m5!3m4!1s0x47c3c4485d19ce43:0xe8eb9253c07c6691!8m2!3d50.8132068!4d4.3822222")!
}
