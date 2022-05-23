import UIKit

class InfoInteractor {
  typealias Dependencies = HasInfoService
  typealias Arguments = Info

  private let dependencies: Dependencies
  private let arguments: Arguments

  init(arguments: Arguments, dependencies: Dependencies) {
    self.arguments = arguments
    self.dependencies = dependencies
  }

  func didLoad() {
    dependencies.infoService.loadAttributedText(for: arguments) { result in
      DispatchQueue.main.async { [weak self] in
        _ = self

        switch result {
        case let .success(attributedText):
          _ = attributedText
        case let .failure(error):
          _ = error
        }
      }
    }
  }
}

final class InfoController: TextViewController {
  typealias Dependencies = HasInfoService

  var didError: ((InfoController, Error) -> Void)?

  private let dependencies: Dependencies
  private let info: Info

  init(info: Info, dependencies: Dependencies) {
    self.info = info
    self.dependencies = dependencies
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    dependencies.infoService.loadAttributedText(for: info) { result in
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }

        switch result {
        case let .success(attributedText):
          self.attributedText = attributedText
        case let .failure(error):
          self.didError?(self, error)
        }
      }
    }
  }
}
