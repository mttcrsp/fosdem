import Combine
import UIKit

final class MoreMainViewController: UISplitViewController {
  typealias Dependencies = HasNavigationService

  private weak var acknowledgementsViewController: AcknowledgementsViewController?
  private weak var moreViewController: MoreViewController?
  private var cancellables: [AnyCancellable] = []
  private let dependencies: Dependencies
  private let viewModel: MoreViewModel

  init(dependencies: Dependencies, viewModel: MoreViewModel) {
    self.dependencies = dependencies
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

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
      viewModel.didSelectItem(.history)
    }

    viewModel.didLoadAcknowledgements
      .receive(on: DispatchQueue.main)
      .sink { [weak self] result in
        guard let self else { return }

        switch result {
        case let .success(acknowledgements):
          let acknowledgementsViewController = AcknowledgementsViewController(acknowledgements: acknowledgements, style: preferredDetailViewControllerStyle)
          acknowledgementsViewController.title = L10n.Acknowledgements.title
          acknowledgementsViewController.delegate = self
          self.acknowledgementsViewController = acknowledgementsViewController
          showDetailViewController(UINavigationController(rootViewController: acknowledgementsViewController))
        case .failure:
          let errorViewController = UIAlertController.makeErrorController()
          moreViewController.present(errorViewController, animated: true)
        }
      }
      .store(in: &cancellables)

    viewModel.didLoadInfo
      .receive(on: DispatchQueue.main)
      .sink { [weak self] result in
        guard let self else { return }

        switch result {
        case let .success((info, item, attributedText)):
          let textViewController = TextViewController()
          textViewController.accessibilityIdentifier = info.accessibilityIdentifier
          textViewController.attributedText = attributedText
          textViewController.title = item.title
          showDetailViewController(UINavigationController(rootViewController: textViewController))
        case .failure:
          let errorViewController = UIAlertController.makeErrorController()
          moreViewController.present(errorViewController, animated: true)
        }
      }
      .store(in: &cancellables)

    viewModel.didOpenAcknowledgement
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.acknowledgementsViewController?.deselectSelectedRow(animated: true)
      }
      .store(in: &cancellables)

    viewModel.didOpenURL
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.moreViewController?.deselectSelectedRow(animated: true)
      }
      .store(in: &cancellables)
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
      if traitCollection.horizontalSizeClass == .regular, viewControllers.count < 2 {
        if moreViewController != nil {
          viewModel.didSelectItem(.history)
        }
      }
    }
  }
}

extension MoreMainViewController {
  func popToRootViewController() {
    if traitCollection.horizontalSizeClass == .compact {
      moreViewController?.navigationController?.popToRootViewController(animated: true)
    }
  }
}

extension MoreMainViewController: MoreViewControllerDelegate {
  func moreViewController(_ moreViewController: MoreViewController, didSelect item: MoreItem) {
    switch item {
    case .code:
      viewModel.didSelectCode()

    case .years:
      let yearsViewController = dependencies.navigationService.makeYearsViewController(withStyle: preferredDetailViewControllerStyle)
      yearsViewController.didError = { [weak self] _, _ in
        self?.moreViewControllerDidFailPresentation()
      }
      showDetailViewController(UINavigationController(rootViewController: yearsViewController))

    case .video:
      let videosViewController = dependencies.navigationService.makeVideosViewController()
      videosViewController.didError = { [weak self] _, _ in
        self?.moreViewControllerDidFailPresentation()
      }
      showDetailViewController(UINavigationController(rootViewController: videosViewController))

    case .transportation:
      let transportationViewController = dependencies.navigationService.makeTransportationViewController()
      showDetailViewController(transportationViewController)

    case .acknowledgements:
      viewModel.didSelectAcknowledgements()

    case .history, .legal, .devrooms:
      viewModel.didSelectItem(item)

    #if DEBUG
    case .overrideTime:
      let dateViewController = dependencies.navigationService.makeDateViewController()
      moreViewController.present(dateViewController, animated: true)

    case .generateDatabase:
      #if targetEnvironment(simulator)
      let alertController = UIAlertController.makeGenerateDatabaseController()
      moreViewController.present(alertController, animated: true)
      #else
      let alertController = UIAlertController.makeGenerateDatabaseUnavailableController()
      moreViewController.present(alertController, animated: true)
      #endif
    #endif
    }
  }

  private func moreViewControllerDidFailPresentation() {
    popToRootViewController()
    let errorViewController = UIAlertController.makeErrorController()
    moreViewController?.present(errorViewController, animated: true)
  }

  private func showDetailViewController(_ detailViewController: UIViewController) {
    moreViewController?.showDetailViewController(detailViewController, sender: nil)
    UIAccessibility.post(notification: .screenChanged, argument: detailViewController.view)
  }
}

extension MoreMainViewController: AcknowledgementsViewControllerDelegate {
  func acknowledgementsViewController(_: AcknowledgementsViewController, didSelect acknowledgement: Acknowledgement) {
    viewModel.didSelectAcknowledgement(acknowledgement)
  }
}

private extension MoreMainViewController {
  var preferredDetailViewControllerStyle: UITableView.Style {
    traitCollection.userInterfaceIdiom == .pad ? .insetGrouped : .grouped
  }
}
