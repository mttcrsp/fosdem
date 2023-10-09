#if DEBUG
import UIKit

final class DateViewController: UIViewController {
  var onChange: (() -> Void)?

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
    onChange?()
  }
}
#endif
