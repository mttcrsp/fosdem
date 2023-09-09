#if DEBUG

import UIKit

protocol DateViewControllerDelegate: AnyObject {
  func dateViewControllerDidChange(_ dateViewController: DateViewController)
}

final class DateViewController: UIViewController {
  weak var delegate: DateViewControllerDelegate?

  private lazy var datePicker = UIDatePicker()

  var date: Date {
    get { datePicker.date }
    set { datePicker.date = newValue }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.addSubview(datePicker)
    view.backgroundColor = .systemBackground

    datePicker.translatesAutoresizingMaskIntoConstraints = false
    datePicker.addTarget(self, action: #selector(didChangeDate), for: .valueChanged)

    NSLayoutConstraint.activate([
      datePicker.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      datePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      datePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
  }

  @objc private func didChangeDate() {
    delegate?.dateViewControllerDidChange(self)
  }
}

#endif
