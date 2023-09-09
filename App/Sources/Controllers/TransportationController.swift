import UIKit

class TransportationController: UINavigationController {
  typealias Dependencies = HasNavigationService & HasOpenService

  private let dependencies: Dependencies

  init(dependencies: Dependencies) {
    self.dependencies = dependencies
    super.init(nibName: nil, bundle: nil)

    var style = UITableView.Style.insetGrouped
    if traitCollection.userInterfaceIdiom == .phone {
      style = .grouped
    }

    let transportationViewController = TransportationViewController(style: style)
    transportationViewController.title = L10n.Transportation.title
    transportationViewController.delegate = self
    viewControllers = [transportationViewController]
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension TransportationController: TransportationViewControllerDelegate {
  func transportationViewController(_ transportationViewController: TransportationViewController, didSelect item: TransportationItem) {
    switch item {
    case .appleMaps:
      self.transportationViewController(transportationViewController, didSelect: .ulbAppleMaps)
    case .googleMaps:
      self.transportationViewController(transportationViewController, didSelect: .ulbGoogleMaps)
    case .bus, .car, .taxi, .plane, .train, .shuttle:
      if let info = item.info {
        let infoViewController = dependencies.navigationService.makeInfoViewController(item.title, info) { [weak self] _, _ in
          self?.transportationViewControllerDidFailPresentation(transportationViewController)
        }
        transportationViewController.show(infoViewController, sender: nil)
      } else {
        assertionFailure("Failed to determine info model for transportation item '\(item)'")
      }
    }
  }

  private func transportationViewController(_ transportationViewController: TransportationViewController, didSelect directionsURL: URL) {
    dependencies.openService.open(directionsURL) { [weak transportationViewController] _ in
      transportationViewController?.deselectSelectedRow(animated: true)
    }
  }

  private func transportationViewControllerDidFailPresentation(_ transportationViewController: TransportationViewController) {
    let errorViewController = UIAlertController.makeErrorController()
    popViewController(animated: true)
    transportationViewController.present(errorViewController, animated: true)
  }
}

private extension URL {
  static var ulbAppleMaps: URL {
    URL(string: "https://maps.apple.com/?address=Avenue%20Franklin%20Roosevelt%2050,%201050%20Brussels,%20Belgium&auid=2450730505287536200&ll=50.812050,4.382236&lsp=9902&q=Universit%C3%A9%20Libre%20de%20Bruxelles&_ext=ChgKBAgEEFcKBAgFEAMKBAgGEBkKBAgKEAESJCkjtQWwbFxJQDFgm0ZDufUQQDkZviUmcHNJQEGgZLl8GBkSQA%3D%3D")!
  }

  static var ulbGoogleMaps: URL {
    URL(string: "https://www.google.com/maps/place/Universit%C3%A9+Libre+de+Bruxelles/@50.8132068,4.3800335,17z/data=!3m1!4b1!4m5!3m4!1s0x47c3c4485d19ce43:0xe8eb9253c07c6691!8m2!3d50.8132068!4d4.3822222")!
  }
}
