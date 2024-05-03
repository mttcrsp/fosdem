import Combine
import UIKit

final class MoreViewModel {
  typealias Dependencies = HasAcknowledgementsService & HasInfoService & HasOpenService & HasYearsService

  private var acknowledgements: [Acknowledgement]?
  let didLoadAcknowledgements = PassthroughSubject<Result<[Acknowledgement], Error>, Never>()
  let didLoadInfo = PassthroughSubject<Result<(Info, MoreItem, NSAttributedString), Error>, Never>()
  let didOpenAcknowledgement = PassthroughSubject<Void, Never>()
  let didOpenURL = PassthroughSubject<Void, Never>()
  private let dependencies: Dependencies

  init(dependencies: Dependencies) {
    self.dependencies = dependencies
  }

  func didSelectAcknowledgements() {
    if let acknowledgements {
      didLoadAcknowledgements.send(.success(acknowledgements))
      return
    }

    do {
      let acknowledgements = try dependencies.acknowledgementsService.loadAcknowledgements()
      self.acknowledgements = acknowledgements
      didLoadAcknowledgements.send(.success(acknowledgements))
    } catch {
      didLoadAcknowledgements.send(.failure(error))
    }
  }

  func didSelectAcknowledgement(_ acknowledgement: Acknowledgement) {
    dependencies.openService.open(acknowledgement.url) { [weak self] _ in
      self?.didOpenAcknowledgement.send()
    }
  }

  func didSelectCode() {
    guard let url = URL.fosdemGithub else { return }
    dependencies.openService.open(url) { [weak self] _ in
      self?.didOpenURL.send()
    }
  }

  func didSelectItem(_ item: MoreItem) {
    guard let info = item.info else { return }
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
