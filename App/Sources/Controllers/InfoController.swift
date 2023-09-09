import Dependencies
import UIKit

final class InfoController: TextViewController {
  var didError: ((InfoController, Error) -> Void)?

  @Dependency(\.infoClient) var infoClient

  private let info: Info

  init(info: Info) {
    self.info = info
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    infoClient.loadAttributedText(info) { result in
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
