import Combine
import UIKit

class TransportationNavigationController: UINavigationController {
  private let viewModel: TransportationViewModel
  private var cancellables: [AnyCancellable] = []

  init(viewModel: TransportationViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)

    let style = traitCollection.userInterfaceIdiom == .phone ? UITableView.Style.insetGrouped : .grouped
    let transportationViewController = TransportationViewController(style: style)
    transportationViewController.title = L10n.Transportation.title
    transportationViewController.delegate = self
    viewControllers = [transportationViewController]

    viewModel.didOpenURL
      .receive(on: DispatchQueue.main)
      .sink {
        transportationViewController.deselectSelectedRow(animated: true)
      }
      .store(in: &cancellables)

    viewModel.didLoadInfo
      .receive(on: DispatchQueue.main)
      .sink { result in
        switch result {
        case let .success((info, item, attributedText)):
          let textViewController = TextViewController()
          textViewController.accessibilityIdentifier = info.accessibilityIdentifier
          textViewController.title = item.title
          textViewController.attributedText = attributedText
          transportationViewController.show(textViewController, sender: nil)
        case .failure:
          let errorViewController = UIAlertController.makeErrorController()
          transportationViewController.present(errorViewController, animated: true)
        }
      }
      .store(in: &cancellables)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension TransportationNavigationController: TransportationViewControllerDelegate {
  func transportationViewController(_: TransportationViewController, didSelect item: TransportationItem) {
    viewModel.didSelect(item)
  }
}

private extension URL {
  static let ulbAppleMaps = URL(string: "https://maps.apple.com/?address=Avenue%20Franklin%20Roosevelt%2050,%201050%20Brussels,%20Belgium&auid=2450730505287536200&ll=50.812050,4.382236&lsp=9902&q=Universit%C3%A9%20Libre%20de%20Bruxelles&_ext=ChgKBAgEEFcKBAgFEAMKBAgGEBkKBAgKEAESJCkjtQWwbFxJQDFgm0ZDufUQQDkZviUmcHNJQEGgZLl8GBkSQA%3D%3D")!
  static let ulbGoogleMaps = URL(string: "https://www.google.com/maps/place/Universit%C3%A9+Libre+de+Bruxelles/@50.8132068,4.3800335,17z/data=!3m1!4b1!4m5!3m4!1s0x47c3c4485d19ce43:0xe8eb9253c07c6691!8m2!3d50.8132068!4d4.3822222")!
}
