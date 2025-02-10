import UIKit

class DisplayTimeZoneViewController: UICollectionViewController {
  typealias Dependencies = HasTimeFormattingService
  
  private struct Item: Hashable {
    var displayTimeZone: DisplayTimeZone
    var isSelected: Bool
  }
 
  private var observer: NSObjectProtocol?
  private var dataSource: UICollectionViewDiffableDataSource<String, Item>?
  private let dependencies: Dependencies
  
  init(dependencies: Dependencies) {
    self.dependencies = dependencies
    
    var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
    configuration.footerMode = .supplementary
    
    let layout = UICollectionViewCompositionalLayout.list(using: configuration)
    super.init(collectionViewLayout: layout)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    title = L10n.TimeZone.title
    navigationItem.largeTitleDisplayMode = .never
    
    let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { cell, _, item in
      var contentConfiguration = cell.defaultContentConfiguration()
      contentConfiguration.secondaryText = item.displayTimeZone.timeZone.localizedName(for: .generic, locale: .current)
      contentConfiguration.text = switch item.displayTimeZone {
      case .conference: L10n.TimeZone.conference
      case .current: L10n.TimeZone.current
      }
      
      cell.contentConfiguration = contentConfiguration
      cell.accessories = item.isSelected ? [.checkmark()] : []
    }
    
    let footerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionFooter) { supplementaryView, _, _ in
      var contentConfiguration = supplementaryView.defaultContentConfiguration()
      contentConfiguration.text = L10n.TimeZone.footer
      supplementaryView.contentConfiguration = contentConfiguration
    }
    
    dataSource = .init(collectionView: collectionView) { collectionView, indexPath, item in
      collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
    }
    dataSource?.supplementaryViewProvider = { collectionView, _, indexPath in
      collectionView.dequeueConfiguredReusableSupplementary(using: footerRegistration, for: indexPath)
    }
    dataSource?.apply(makeSnapshot(), animatingDifferences: false)
    observer = dependencies.timeFormattingService.addObserverForDisplayTimeZoneChanges { [weak self] in
      if let self {
        dataSource?.apply(makeSnapshot(), animatingDifferences: false)
      }
    }
  }
  
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: true)
    
    if let dataSource, let item = dataSource.itemIdentifier(for: indexPath) {
      dependencies.timeFormattingService.displayTimeZone = item.displayTimeZone
      dataSource.apply(makeSnapshot(), animatingDifferences: false)
    }
  }
  
  private func makeSnapshot() -> NSDiffableDataSourceSnapshot<String, Item> {
    let items = DisplayTimeZone.allCases.map { displayTimeZone in
      let isSelected = dependencies.timeFormattingService.displayTimeZone == displayTimeZone
      return Item(displayTimeZone: displayTimeZone, isSelected: isSelected)
    }
    
    var snapshot = NSDiffableDataSourceSnapshot<String, Item>()
    snapshot.appendSections(["main"])
    snapshot.appendItems(items)
    return snapshot
  }
}
