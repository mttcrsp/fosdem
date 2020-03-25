#if DEBUG

    import UIKit

    protocol TimeViewControllerDelegate: AnyObject {
        func timeViewControllerDidChange(_ timeViewController: TimeViewController)
    }

    final class TimeViewController: UIViewController {
        weak var delegate: TimeViewControllerDelegate?

        private lazy var datePicker = UIDatePicker()

        var date: Date? {
            datePicker.date
        }

        override func loadView() {
            view = datePicker
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            preferredContentSize = datePicker.intrinsicContentSize
            datePicker.addTarget(self, action: #selector(didChangeDate), for: .valueChanged)
        }

        @objc private func didChangeDate() {
            delegate?.timeViewControllerDidChange(self)
        }
    }

#endif
