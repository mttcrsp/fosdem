import UIKit

enum MoreSection: CaseIterable {
    #if DEBUG
        case debug
    #endif

    case about
    case other
}

enum MoreItem: CaseIterable {
    #if DEBUG
        case `import`
    #endif

    case years
    case history
    case devrooms
    case transportation
    case acknowledgements
}

final class MoreController: UINavigationController {
    private weak var eventsViewController: EventsViewController?
    private weak var moreViewController: MoreViewController?

    private(set) var acknowledgements: [Acknowledgement] = []
    private(set) var events: [Event] = []

    private let services: Services

    init(services: Services) {
        self.services = services
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 11.0, *) {
            navigationBar.prefersLargeTitles = true
        }

        viewControllers = [makeMoreViewController()]
    }
}

extension MoreController: MoreViewControllerDelegate {
    func moreViewController(_ moreViewController: MoreViewController, didSelect item: MoreItem) {
        switch item {
        #if DEBUG
            case .import: moreViewControllerDidSelectImport(moreViewController)
        #endif
        case .years: moreViewControllerDidSelectYears(moreViewController)
        case .history: moreViewControllerDidSelectHistory(moreViewController)
        case .devrooms: moreViewControllerDidSelectDevrooms(moreViewController)
        case .transportation: moreViewControllerDidSelectTransportation(moreViewController)
        case .acknowledgements: moreViewControllerDidSelectAcknowledgements(moreViewController)
        }
    }

    private func moreViewControllerDidSelectYears(_ moreViewController: MoreViewController) {
        print(#function, moreViewController)
    }

    private func moreViewControllerDidSelectTransportation(_ moreViewController: MoreViewController) {
        print(#function, moreViewController)
    }

    private func moreViewControllerDidSelectHistory(_ moreViewController: MoreViewController) {
        moreViewController.show(makeHistoryViewController(), sender: nil)
    }

    private func moreViewControllerDidSelectDevrooms(_ moreViewController: MoreViewController) {
        moreViewController.show(makeDevroomsViewController(), sender: nil)
    }

    #if DEBUG
        private func moreViewControllerDidSelectImport(_: MoreViewController) {
            guard let url = Bundle.main.url(forResource: "2020", withExtension: "xml") else {
                return assertionFailure("2020 schedule XML was not found in the main bundle")
            }

            guard let data = try? Data(contentsOf: url) else {
                return assertionFailure("Failed to load data for the 2020 schedule")
            }

            let parser = ScheduleXMLParser(data: data)

            guard parser.parse(), let schedule = parser.schedule else {
                let error = parser.validationError ?? parser.parseError
                return assertionFailure(error?.localizedDescription ?? "Failed to parse the 2020 schedule")
            }

            let importSchedule = ImportSchedule(schedule: schedule)
            services.persistenceService.performWrite(importSchedule) { error in
                assert(error == nil)
            }
        }
    #endif

    private func moreViewControllerDidSelectAcknowledgements(_ moreViewController: MoreViewController) {
        DispatchQueue.global().async { [weak self, weak moreViewController] in
            let acknowledgements = self?.services.acknowledgementsService.loadAcknowledgements()

            DispatchQueue.main.async {
                guard let self = self, let moreViewController = moreViewController else { return }

                if let acknowledgements = acknowledgements {
                    self.acknowledgements = acknowledgements
                    moreViewController.show(self.makeAcknowledgementsViewController(), sender: nil)
                } else {
                    moreViewController.present(ErrorController(), animated: true)
                }
            }
        }
    }
}

extension MoreController: AcknowledgementsViewControllerDataSource, AcknowledgementsViewControllerDelegate {
    func acknowledgementsViewController(_ acknowledgementsViewController: AcknowledgementsViewController, didSelect acknowledgement: Acknowledgement) {
        DispatchQueue.global().async { [weak self, weak acknowledgementsViewController] in
            guard let self = self else { return }

            let acknowledgementsService = self.services.acknowledgementsService
            var license = acknowledgementsService.loadLicense(for: acknowledgement)
            if let licence = license {
                license = acknowledgementsService.makeFormattedLicense(fromLicense: licence)
            }

            DispatchQueue.main.async { [weak self] in
                guard let self = self, let acknowledgementsViewController = acknowledgementsViewController else { return }

                if let license = license {
                    let licenseViewController = self.makeLicenseViewController(for: acknowledgement, withLicense: license)
                    acknowledgementsViewController.show(licenseViewController, sender: nil)
                } else {
                    let errorViewController = ErrorController()
                    acknowledgementsViewController.present(errorViewController, animated: true)
                }
            }
        }
    }
}

extension MoreController: EventsViewControllerDataSource, EventsViewControllerDelegate {
    func events(in _: EventsViewController) -> [Event] {
        events
    }

    func eventsViewController(_: EventsViewController, didSelect event: Event) {
        let eventViewController = makeEventViewController(for: event)
        moreViewController?.show(eventViewController, sender: nil)
    }
}

extension MoreController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text, !query.isEmpty else { return }

        let operation = EventsForSearch(query: query)
        services.persistenceService.performRead(operation) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .failure:
                    break
                case let .success(events):
                    self?.events = events
                    self?.eventsViewController?.reloadData()
                }
            }
        }
    }
}

private extension MoreController {
    func makeMoreViewController() -> MoreViewController {
        let moreViewController = MoreViewController(style: .grouped)
        moreViewController.title = NSLocalizedString("more.title", comment: "")
        moreViewController.addSearchViewController(makeSearchController())
        moreViewController.delegate = self
        self.moreViewController = moreViewController
        return moreViewController
    }

    func makeHistoryViewController() -> TextViewController {
        let historyViewController = TextViewController()
        historyViewController.title = NSLocalizedString("history.title", comment: "")
        historyViewController.text = NSLocalizedString("history.body", comment: "")
        historyViewController.extendedLayoutIncludesOpaqueBars = true
        historyViewController.hidesBottomBarWhenPushed = true
        return historyViewController
    }

    func makeDevroomsViewController() -> TextViewController {
        let devroomsViewController = TextViewController()
        devroomsViewController.title = NSLocalizedString("devrooms.title", comment: "")
        devroomsViewController.text = NSLocalizedString("devrooms.body", comment: "")
        devroomsViewController.extendedLayoutIncludesOpaqueBars = true
        devroomsViewController.hidesBottomBarWhenPushed = true
        return devroomsViewController
    }

    func makeAcknowledgementsViewController() -> AcknowledgementsViewController {
        let acknowledgementsViewController = AcknowledgementsViewController(style: .grouped)
        acknowledgementsViewController.title = NSLocalizedString("acknowledgements.title", comment: "")
        acknowledgementsViewController.extendedLayoutIncludesOpaqueBars = true
        acknowledgementsViewController.hidesBottomBarWhenPushed = true
        acknowledgementsViewController.dataSource = self
        acknowledgementsViewController.delegate = self
        return acknowledgementsViewController
    }

    func makeLicenseViewController(for acknowledgement: Acknowledgement, withLicense license: String) -> TextViewController {
        let licenseViewController = TextViewController()
        licenseViewController.extendedLayoutIncludesOpaqueBars = true
        licenseViewController.title = acknowledgement
        licenseViewController.text = license
        return licenseViewController
    }

    func makeSearchController() -> UISearchController {
        let searchController = UISearchController(searchResultsController: makeEventsViewController())
        searchController.searchBar.placeholder = NSLocalizedString("more.search.prompt", comment: "")
        searchController.searchResultsUpdater = self
        return searchController
    }

    func makeEventsViewController() -> EventsViewController {
        let eventsViewController = EventsViewController(style: .grouped)
        eventsViewController.dataSource = self
        eventsViewController.delegate = self
        self.eventsViewController = eventsViewController
        return eventsViewController
    }

    func makeEventViewController(for event: Event) -> EventController {
        let eventController = EventController(event: event, services: services)
        eventController.hidesBottomBarWhenPushed = true
        return eventController
    }
}

extension MoreSection {
    var items: [MoreItem] {
        switch self {
        #if DEBUG
            case .debug: return [.import]
        #endif
        case .other: return [.years, .acknowledgements]
        case .about: return [.history, .devrooms, .transportation]
        }
    }

    var title: String? {
        switch self {
        #if DEBUG
            case .debug: return "Debug"
        #endif
        case .about: return NSLocalizedString("more.section.about", comment: "")
        case .other: return NSLocalizedString("more.section.other", comment: "")
        }
    }
}
