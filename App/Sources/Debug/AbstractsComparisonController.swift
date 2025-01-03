#if DEBUG

import UIKit

final class AbstractsInspectionController: UICollectionViewController {
  typealias Dependencies = HasPersistenceService

  private enum Section: Hashable {
    case events
  }

  private lazy var events: [Event] = {
    do {
      var events: [Event] = []
      for track in try dependencies.persistenceService.performReadSync(GetAllTracks()) {
        for event in try dependencies.persistenceService.performReadSync(GetEventsByTrack(track: track.name)) {
          events.append(event)
        }
      }
      return events.sorted { $0.id < $1.id }
    } catch {
      assertionFailure(error.localizedDescription)
      return []
    }
  }()

  private var hiddenEventsIDs: [Int] {
    get { defaults.array(forKey: "hidden_events_ids") as? [Int] ?? [] }
    set { defaults.set(newValue, forKey: "hidden_events_ids") }
  }

  private var dataSource: UICollectionViewDiffableDataSource<Section, Event>?
  private let defaults = UserDefaults.standard
  private let dependencies: Dependencies

  init(dependencies: Dependencies) {
    self.dependencies = dependencies

    let collectionViewLayout = UICollectionViewCompositionalLayout.list(using: .init(appearance: .plain))
    super.init(collectionViewLayout: collectionViewLayout)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    collectionView.delegate = self

    let registration = UICollectionView.CellRegistration<UICollectionViewListCell, Event> { cell, _, event in
      let attributes = [NSAttributedString.Key.font: UIFont.fos_preferredFont(forTextStyle: .body)]
      let attributedText = NSMutableAttributedString()
      attributedText.append(.init(string: event.id.description, attributes: attributes))
      attributedText.append(.init(string: "\n\n------------------\n\n"))
      if let abstract = event.abstract {
        if let attributedAbstract = NSAttributedString(html: abstract) {
          attributedText.append(attributedAbstract)
        }
      }

      var configuration = cell.defaultContentConfiguration()
      configuration.attributedText = attributedText
      cell.contentConfiguration = configuration
    }

    dataSource = .init(collectionView: collectionView) { collectionView, indexPath, event in
      collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: event)
    }

    dataSource?.apply(makeSnapshot(), animatingDifferences: false)
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
      dataSource?.apply(makeSnapshot(), animatingDifferences: false)
    }
  }

  private func makeSnapshot() -> NSDiffableDataSourceSnapshot<Section, Event> {
    let hiddenEventsIDs = Set(hiddenEventsIDs)
    let events = events.filter { !hiddenEventsIDs.contains($0.id) }
      // Use this filter to select the type of abstacts you are interested in
      // inspecting
      .filter { $0.abstract?.contains("<hr") == true }
      // Use this filter to focus on a single event (== 4607) or exclude events
      // that you have already inspected. (>= 4607)
      .filter { $0.id > 5933 }

    var snapshot = NSDiffableDataSourceSnapshot<Section, Event>()
    snapshot.appendSections([.events])
    snapshot.appendItems(events, toSection: .events)
    return snapshot
  }

  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: true)

    if let event = dataSource?.itemIdentifier(for: indexPath) {
      hiddenEventsIDs.append(event.id)
      dataSource?.apply(makeSnapshot(), animatingDifferences: true)
    }
  }
}

#endif
