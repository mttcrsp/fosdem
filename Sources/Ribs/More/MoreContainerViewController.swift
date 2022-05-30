import RIBs
import UIKit

protocol MorePresentableListener: AnyObject {
  func deselectVideos()
  func deselectYears()

  func select(_ acknowledgement: Acknowledgement)
  func select(_ item: MoreItem)
  func select(_ item: TransportationItem)
  #if DEBUG
  func select(_ date: Date)
  #endif
}

final class MoreContainerViewController: UISplitViewController {
  weak var listener: MorePresentableListener?

  private(set) var acknowledgements: [Acknowledgement] = []

  private weak var acknowledgementsViewController: AcknowledgementsViewController?
  private weak var moreViewController: MoreViewController?
  private weak var transportationViewController: TransportationViewController?
  private weak var videosViewController: UIViewController?
  private weak var yearsViewController: UIViewController?

  override func viewDidLoad() {
    super.viewDidLoad()

    let moreViewController = MoreViewController(style: .grouped)
    moreViewController.title = L10n.More.title
    moreViewController.delegate = self
    self.moreViewController = moreViewController

    let moreNavigationController = UINavigationController(rootViewController: moreViewController)
    moreNavigationController.navigationBar.prefersLargeTitles = true
    viewControllers = [moreNavigationController]

    if traitCollection.horizontalSizeClass == .regular {
      self.moreViewController(moreViewController, didSelect: .history)
    }
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
      if traitCollection.horizontalSizeClass == .regular, viewControllers.count < 2 {
        if let moreViewController = moreViewController {
          self.moreViewController(moreViewController, didSelect: .history)
        }
      }
    }
  }
}

extension MoreContainerViewController: MoreViewControllable {
  func showVideos(_ videosViewControllable: ViewControllable) {
    let videosViewController = videosViewControllable.uiviewController
    self.videosViewController = videosViewController
    showDetailViewController(videosViewController)
  }

  func showYears(_ yearsViewControllable: ViewControllable) {
    let yearsViewController = yearsViewControllable.uiviewController
    self.yearsViewController = yearsViewController
    showDetailViewController(yearsViewController)
  }
}

extension MoreContainerViewController: MorePresentable {
  func deselectSelectedItem() {
    moreViewController?.deselectSelectedRow(animated: true)
  }

  func deselectSelectedAcknowledgment() {
    acknowledgementsViewController?.deselectSelectedRow(animated: true)
  }

  func deselectSelectedTransportationItem() {
    transportationViewController?.deselectSelectedRow(animated: true)
  }

  func hideVideos() {
    if let moreViewController = moreViewController {
      self.moreViewController(moreViewController, didSelect: .history)
    }
  }

  func hideYears() {
    if let moreViewController = moreViewController {
      self.moreViewController(moreViewController, didSelect: .history)
    }
  }

  func showAcknowledgements(_ acknowledgements: [Acknowledgement]) {
    self.acknowledgements = acknowledgements

    let acknowledgementsViewController = AcknowledgementsViewController(style: preferredDetailViewControllerStyle)
    acknowledgementsViewController.title = L10n.Acknowledgements.title
    acknowledgementsViewController.dataSource = self
    acknowledgementsViewController.delegate = self
    self.acknowledgementsViewController = acknowledgementsViewController

    let acknowledgmentsNavigationController = UINavigationController(rootViewController: acknowledgementsViewController)
    showDetailViewController(acknowledgmentsNavigationController)
  }

  func showError() {
    let errorViewController = UIAlertController.makeErrorController()
    moreViewController?.present(errorViewController, animated: true)
  }

  func showInfo(_ info: Info, attributedString: NSAttributedString) {
    let infoViewController = makeInfoViewController(with: info, attributedText: attributedString)
    let infoNavigationController = UINavigationController(rootViewController: infoViewController)
    showDetailViewController(infoNavigationController)
  }

  func showTransportation() {
    let transportationViewController = TransportationViewController(style: preferredDetailViewControllerStyle)
    transportationViewController.title = L10n.Transportation.title
    transportationViewController.delegate = self
    self.transportationViewController = transportationViewController

    let transportationNavigationController = UINavigationController(rootViewController: transportationViewController)
    transportationNavigationController.viewControllers = [transportationViewController]
    showDetailViewController(transportationNavigationController)
  }

  func showTransportationInfo(_ info: Info, attributedString: NSAttributedString) {
    let infoViewController = makeInfoViewController(with: info, attributedText: attributedString)
    transportationViewController?.show(infoViewController, sender: nil)
  }

  #if DEBUG
  func showDate(_ date: Date) {
    let dateViewController = DateViewController()
    dateViewController.delegate = self
    dateViewController.date = date
    moreViewController?.present(dateViewController, animated: true)
  }
  #endif
}

extension MoreContainerViewController: MoreViewControllerDelegate {
  func moreViewController(_: MoreViewController, didSelect item: MoreItem) {
    listener?.select(item)
  }
}

extension MoreContainerViewController: AcknowledgementsViewControllerDataSource, AcknowledgementsViewControllerDelegate {
  func acknowledgementsViewController(_: AcknowledgementsViewController, didSelect acknowledgement: Acknowledgement) {
    listener?.select(acknowledgement)
  }
}

extension MoreContainerViewController: TransportationViewControllerDelegate {
  func transportationViewController(_: TransportationViewController, didSelect item: TransportationItem) {
    listener?.select(item)
  }
}

#if DEBUG
extension MoreContainerViewController: UIPopoverPresentationControllerDelegate, DateViewControllerDelegate {
  func dateViewControllerDidChange(_ dateViewController: DateViewController) {
    listener?.select(dateViewController.date)
  }
}
#endif

private extension MoreContainerViewController {
  var preferredDetailViewControllerStyle: UITableView.Style {
    if traitCollection.userInterfaceIdiom == .pad {
      return .fos_insetGrouped
    } else {
      return .grouped
    }
  }

  func showDetailViewController(_ detailViewController: UIViewController) {
    if detailViewController != videosViewController {
      listener?.deselectVideos()
    }

    if detailViewController != yearsViewController {
      listener?.deselectYears()
    }

    moreViewController?.showDetailViewController(detailViewController, sender: nil)
    UIAccessibility.post(notification: .screenChanged, argument: detailViewController.view)
  }

  func makeInfoViewController(with info: Info, attributedText: NSAttributedString) -> TextViewController {
    let infoViewController = TextViewController()
    infoViewController.accessibilityIdentifier = info.accessibilityIdentifier
    infoViewController.attributedText = attributedText
    infoViewController.title = info.title
    return infoViewController
  }
}
