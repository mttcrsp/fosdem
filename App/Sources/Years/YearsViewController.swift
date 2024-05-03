import Combine
import UIKit

class YearsViewController: UITableViewController {
  typealias Dependencies = HasNavigationService

  var didError: ((UIViewController, Error) -> Void)?
  private var cancellables: [AnyCancellable] = []
  private let dependencies: Dependencies
  private let viewModel: YearsViewModel

  init(style: UITableView.Style, dependencies: Dependencies, viewModel: YearsViewModel) {
    self.dependencies = dependencies
    self.viewModel = viewModel
    super.init(style: style)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    title = L10n.Years.title
    tableView.estimatedRowHeight = 44
    tableView.tableFooterView = UIView()
    tableView.rowHeight = UITableView.automaticDimension
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)

    viewModel.$loadingState
      .receive(on: DispatchQueue.main)
      .sink { [weak self] state in
        guard let self else { return }

        if case .loading = state {
          tableView.allowsSelection = false
        } else {
          tableView.allowsSelection = true
        }

        switch state {
        case .idle: break
        case let .loading(year, _), let .success(year, _), let .failure(year, _):
          deselectSelectedRow(animated: true)
          if let index = viewModel.years.firstIndex(of: year) {
            let indexPath = IndexPath(row: index, section: 0)
            if let cell = tableView.cellForRow(at: indexPath) {
              cell.setDownloadState(downloadState(at: indexPath))
            }
          }
        }

        switch state {
        case .idle, .loading:
          break

        case let .success(year, persistenceService):
          let yearViewController = dependencies.navigationService.makeYearViewController(for: persistenceService)
          yearViewController.title = year.description
          yearViewController.navigationItem.largeTitleDisplayMode = .never
          yearViewController.didError = { [weak self] viewController, error in
            self?.didError?(viewController, error)
          }
          show(yearViewController, sender: nil)

        case let .failure(_, error as YearsService.Error) where error == .yearNotAvailable:
          let title = L10n.Years.Unavailable.title, message = L10n.Years.Unavailable.message
          let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
          alertController.addAction(.init(title: L10n.Years.Unavailable.dismiss, style: .default))
          present(alertController, animated: true)

        case let .failure(year, error as URLError) where error.code == .notConnectedToInternet:
          let retryHandler: () -> Void = { [weak self] in self?.viewModel.didSelect(year) }
          let errorViewController = UIAlertController.makeNoInternetController(withRetryHandler: retryHandler)
          present(errorViewController, animated: true)

        case .failure:
          let errorViewController = UIAlertController.makeErrorController()
          present(errorViewController, animated: true)
        }
      }
      .store(in: &cancellables)

    viewModel.didLoad()
  }

  override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    viewModel.years.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let year = year(at: indexPath)
    let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
    cell.accessibilityIdentifier = year.description
    cell.textLabel?.font = .fos_preferredFont(forTextStyle: .body)
    cell.textLabel?.text = L10n.Years.year(year)
    cell.imageView?.image = UIImage(systemName: "\(year % 2000).circle.fill")
    cell.setDownloadState(downloadState(at: indexPath))
    return cell
  }

  override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    viewModel.didSelect(year(at: indexPath))
  }

  private func year(at indexPath: IndexPath) -> Year {
    viewModel.years[indexPath.row]
  }

  private func downloadState(at indexPath: IndexPath) -> YearDownloadState {
    viewModel.downloadState(for: viewModel.years[indexPath.row])
  }
}

private extension UITableViewCell {
  func setDownloadState(_ state: YearDownloadState) {
    switch state {
    case .inProgress:
      let indicatorView = UIActivityIndicatorView(style: .medium)
      indicatorView.startAnimating()
      accessoryView = indicatorView
      accessoryType = .none
    case .available, .completed:
      accessoryView = nil
      accessoryType = .disclosureIndicator
    }
  }
}
