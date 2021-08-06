import UIKit

final class InfoController {
  typealias Dependencies = HasInfoService

  var didError: ((UIViewController, Error) -> Void)?

  private weak var infoViewController: TextViewController?

  private let dependencies: Dependencies
  private let info: Info

  init(info: Info, dependencies: Dependencies) {
    self.info = info
    self.dependencies = dependencies
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func loadInfo() {
    dependencies.infoService.loadAttributedText(for: info) { result in
      DispatchQueue.main.async { [weak self] in
        guard let self = self, let infoViewController = self.infoViewController else { return }

        switch result {
        case let .success(attributedText):
          infoViewController.attributedText = attributedText
        case let .failure(error):
          self.didError?(infoViewController, error)
        }
      }
    }
  }

  func makeInfoViewController() -> TextViewController {
    let infoViewController = TextViewController()
    self.infoViewController = infoViewController
    return infoViewController
  }
}
