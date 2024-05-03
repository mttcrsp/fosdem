#if DEBUG

final class DateViewModel {
  typealias Dependencies = HasTimeService

  private let dependencies: Dependencies

  init(dependencies: Dependencies) {
    self.dependencies = dependencies
  }

  var date: Date {
    get { dependencies.timeService.now }
    set { dependencies.timeService.now = newValue }
  }
}

import UIKit

final class DateViewController: UIViewController {
  private lazy var datePicker = UIDatePicker()
  private let viewModel: DateViewModel

  init(viewModel: DateViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .systemBackground
    view.addSubview(datePicker)
    datePicker.translatesAutoresizingMaskIntoConstraints = false
    datePicker.addTarget(self, action: #selector(didChangeDate), for: .valueChanged)

    NSLayoutConstraint.activate([
      datePicker.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      datePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      datePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
  }

  @objc private func didChangeDate() {
    viewModel.date = datePicker.date
  }
}

#endif
