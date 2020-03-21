import UIKit

enum MoreSection: CaseIterable {
    case about
    case other
    #if DEBUG
        case debug
    #endif
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
    private weak var resultsViewController: EventsViewController?
    private weak var moreViewController: MoreViewController?

    private(set) var acknowledgements: [Acknowledgement] = []
    private(set) var events: [Event] = []
    private var years: [String] = []

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
        services.yearsService.loadYears { years in
            DispatchQueue.main.async { [weak self, weak moreViewController] in
                if let self = self {
                    self.years = years
                    moreViewController?.show(self.makeYearsViewController(), sender: nil)
                }
            }
        }
    }

    private func moreViewControllerDidSelectHistory(_ moreViewController: MoreViewController) {
        showInfoViewController(from: moreViewController, withTitle: MoreItem.history.title, for: .history)
    }

    private func moreViewControllerDidSelectDevrooms(_ moreViewController: MoreViewController) {
        showInfoViewController(from: moreViewController, withTitle: MoreItem.devrooms.title, for: .devrooms)
    }

    private func moreViewControllerDidSelectTransportation(_ moreViewController: MoreViewController) {
        moreViewController.show(makeTransportationViewController(), sender: nil)
    }

    private func showInfoViewController(from _: UIViewController, withTitle title: String, for info: Info) {
        services.infoService.loadAttributedText(for: info) { [weak moreViewController] attributedText in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                if let attributedText = attributedText {
                    let textViewController = self.makeTextViewController()
                    textViewController.attributedText = attributedText
                    textViewController.title = title
                    moreViewController?.show(textViewController, sender: nil)
                } else {
                    moreViewController?.present(ErrorController(), animated: true)
                }
            }
        }
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

                    let emptyFormat = NSLocalizedString("more.search.empty", comment: "")
                    let emptyString = String(format: emptyFormat, query)
                    self?.resultsViewController?.emptyBackgroundText = emptyString
                    self?.resultsViewController?.reloadData()
                }
            }
        }
    }
}

extension MoreController: TransportationViewControllerDelegate {
    func transportationViewController(_ transportationViewController: TransportationViewController, didSelect item: TransportationViewController.Item) {
        switch item {
        case .appleMaps:
            UIApplication.shared.open(.ulbAppleMaps) { [weak transportationViewController] _ in
                transportationViewController?.deselectSelectedRow(animated: true)
            }
        case .googleMaps:
            UIApplication.shared.open(.ulbGoogleMaps) { [weak transportationViewController] _ in
                transportationViewController?.deselectSelectedRow(animated: true)
            }
        case .bus:
            showInfoViewController(from: transportationViewController, withTitle: item.title, for: .bus)
        case .shuttle:
            showInfoViewController(from: transportationViewController, withTitle: item.title, for: .shuttle)
        case .train:
            showInfoViewController(from: transportationViewController, withTitle: item.title, for: .train)
        case .car:
            showInfoViewController(from: transportationViewController, withTitle: item.title, for: .car)
        case .plane:
            showInfoViewController(from: transportationViewController, withTitle: item.title, for: .plane)
        case .taxi:
            showInfoViewController(from: transportationViewController, withTitle: item.title, for: .taxi)
        }
    }
}

extension MoreController: YearsViewControllerDataSource, YearsViewControllerDelegate {
    func numberOfYears(in _: YearsViewController) -> Int {
        years.count
    }

    func yearsViewController(_: YearsViewController, yearAt index: Int) -> String {
        years[index]
    }

    func yearsViewController(_ yearsViewController: YearsViewController, didSelect year: String) {
        services.yearsService.loadURL(forYear: year) { [weak self, weak yearsViewController] url in
            guard let self = self, let yearsViewController = yearsViewController else { return }

            guard let url = url else {
                return self.presentYearErrorViewController(from: yearsViewController)
            }

            do {
                let persistenceService = try PersistenceService(path: url.path, migrations: .allMigrations)
                self.showYearViewController(forYear: year, with: persistenceService, from: yearsViewController)
            } catch {
                assertionFailure(error.localizedDescription)
                self.presentYearErrorViewController(from: yearsViewController)
            }
        }
    }

    private func presentYearErrorViewController(from yearsViewController: YearsViewController) {
        DispatchQueue.main.async { [weak yearsViewController] in
            yearsViewController?.present(ErrorController(), animated: true)
        }
    }

    private func showYearViewController(forYear year: String, with persistenceService: PersistenceService, from yearsViewController: YearsViewController) {
        DispatchQueue.main.async { [weak self, weak yearsViewController] in
            guard let self = self else { return }

            let yearViewController = self.makeYearViewController(forYear: year, with: persistenceService)
            yearsViewController?.show(yearViewController, sender: nil)
        }
    }
}

extension MoreController: YearControllerDelegate {
    func yearControllerDidError(_: YearController) {
        popToRootViewController(animated: true)
        present(ErrorController(), animated: true)
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

    func makeTextViewController() -> TextViewController {
        let textViewController = TextViewController()
        textViewController.extendedLayoutIncludesOpaqueBars = true
        textViewController.hidesBottomBarWhenPushed = true
        return textViewController
    }

    func makeYearsViewController() -> YearsViewController {
        let yearsViewController = YearsViewController()
        yearsViewController.title = NSLocalizedString("years.title", comment: "")
        yearsViewController.extendedLayoutIncludesOpaqueBars = true
        yearsViewController.hidesBottomBarWhenPushed = true
        yearsViewController.dataSource = self
        yearsViewController.delegate = self
        return yearsViewController
    }

    private func makeTransportationViewController() -> TransportationViewController {
        let transportationViewController = TransportationViewController(style: .grouped)
        transportationViewController.title = NSLocalizedString("transportation.title", comment: "")
        transportationViewController.extendedLayoutIncludesOpaqueBars = true
        transportationViewController.hidesBottomBarWhenPushed = true
        transportationViewController.delegate = self
        return transportationViewController
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
        let searchController = UISearchController(searchResultsController: makeResultsViewController())
        searchController.searchBar.placeholder = NSLocalizedString("more.search.prompt", comment: "")
        searchController.searchResultsUpdater = self
        return searchController
    }

    func makeResultsViewController() -> EventsViewController {
        let resultsViewController = EventsViewController(style: .grouped)
        resultsViewController.dataSource = self
        resultsViewController.delegate = self
        self.resultsViewController = resultsViewController
        return resultsViewController
    }

    func makeEventViewController(for event: Event) -> EventController {
        let eventController = EventController(event: event, favoritesService: services.favoritesService)
        eventController.hidesBottomBarWhenPushed = true
        return eventController
    }

    func makeYearViewController(forYear year: String, with persistenceService: PersistenceService) -> YearController {
        let yearController = YearController(year: year, persistenceService: persistenceService)
        yearController.extendedLayoutIncludesOpaqueBars = true
        yearController.delegate = self
        yearController.title = year

        if #available(iOS 11.0, *) {
            yearController.navigationItem.largeTitleDisplayMode = .never
        }

        return yearController
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

extension MoreItem {
    var title: String {
        switch self {
        case .years: return NSLocalizedString("years.title", comment: "")
        case .history: return NSLocalizedString("history.title", comment: "")
        case .devrooms: return NSLocalizedString("devrooms.title", comment: "")
        case .transportation: return NSLocalizedString("transportation.title", comment: "")
        case .acknowledgements: return NSLocalizedString("acknowledgements.title", comment: "")
        #if DEBUG
            case .import: return NSLocalizedString("import.title", comment: "")
        #endif
        }
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
