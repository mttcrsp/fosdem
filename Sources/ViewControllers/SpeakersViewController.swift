import UIKit

protocol SpeakersViewControllerDelegate: AnyObject {
    func speakersViewController(_ speakersViewController: SpeakersViewController, didSelect person: Person)
}

protocol SpeakersViewControllerDataSource: AnyObject {
    var people: [Person] { get }
}

final class SpeakersViewController: UITableViewController {
    weak var dataSource: SpeakersViewControllerDataSource?
    weak var delegate: SpeakersViewControllerDelegate?

    private var people: [Person] {
        dataSource?.people ?? []
    }

    init() {
        if #available(iOS 13.0, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .grouped)
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.reuseIdentifier)
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        people.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.reuseIdentifier, for: indexPath)
        cell.configure(with: person(at: indexPath))
        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.speakersViewController(self, didSelect: person(at: indexPath))
    }

    private func person(at indexPath: IndexPath) -> Person {
        people[indexPath.row]
    }
}

private extension UITableViewCell {
    func configure(with person: Person) {
        textLabel?.numberOfLines = 0
        textLabel?.text = person.name
        accessoryType = .disclosureIndicator
    }
}
