import CoreLocation
import UIKit

protocol MapControlsViewDelegate: AnyObject {
  func controlsViewDidTapReset(_ controlsView: MapControlsView)
  func controlsViewDidTapLocation(_ controlsView: MapControlsView)
}

final class MapControlsView: UIView {
  weak var delegate: MapControlsViewDelegate?

  var authorizationStatus: CLAuthorizationStatus = .notDetermined {
    didSet { didChangeAuthorizationStatus() }
  }

  private let resetButton = MapControlView()
  private let locationButton = MapControlView()

  override init(frame: CGRect) {
    super.init(frame: frame)

    locationButton.title = authorizationStatus.title
    locationButton.image = CLAuthorizationStatus.notDetermined.image
    locationButton.accessibilityLabel = authorizationStatus.title
    locationButton.accessibilityIdentifier = authorizationStatus.identifier
    locationButton.addTarget(self, action: #selector(didTapLocation), for: .touchUpInside)

    resetButton.accessibilityIdentifier = "reset"
    resetButton.accessibilityLabel = L10n.Map.reset
    resetButton.addTarget(self, action: #selector(didTapReset), for: .touchUpInside)
    resetButton.image = UIImage.fos_systemImage(withName: "arrow.counterclockwise")
    resetButton.title = L10n.Map.reset

    let separatorView = UIView()
    separatorView.backgroundColor = .fos_separator

    let backgroundView = UIView()
    backgroundView.backgroundColor = .fos_tertiarySystemBackground
    backgroundView.translatesAutoresizingMaskIntoConstraints = false
    backgroundView.layer.cornerRadius = 8
    backgroundView.layer.shadowRadius = 8
    backgroundView.layer.shadowOpacity = 0.2
    backgroundView.layer.shadowOffset = .zero
    backgroundView.layer.masksToBounds = true
    backgroundView.layer.shadowColor = UIColor.black.cgColor
    addSubview(backgroundView)

    let stackView = UIStackView(arrangedSubviews: [locationButton, separatorView, resetButton])
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    addSubview(stackView)

    NSLayoutConstraint.activate([
      separatorView.heightAnchor.constraint(equalToConstant: 1 / traitCollection.displayScale),

      backgroundView.topAnchor.constraint(equalTo: topAnchor),
      backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
      backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
      backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),

      stackView.topAnchor.constraint(equalTo: topAnchor),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc private func didTapReset() {
    delegate?.controlsViewDidTapReset(self)
  }

  @objc private func didTapLocation() {
    delegate?.controlsViewDidTapLocation(self)
  }

  private func didChangeAuthorizationStatus() {
    locationButton.image = authorizationStatus.image
    locationButton.title = authorizationStatus.title
    locationButton.accessibilityLabel = authorizationStatus.title
    locationButton.accessibilityIdentifier = authorizationStatus.identifier
  }
}

extension CLAuthorizationStatus {
  var title: String {
    switch self {
    case .notDetermined:
      return L10n.Map.location
    case .authorizedWhenInUse, .authorizedAlways:
      return L10n.Map.Location.disable
    case .denied, .restricted:
      return L10n.Map.Location.enable
    @unknown default:
      return L10n.Map.location
    }
  }

  var identifier: String {
    switch self {
    case .notDetermined:
      return "location"
    case .authorizedWhenInUse, .authorizedAlways:
      return "location_available"
    case .denied, .restricted:
      return "location_unavailable"
    @unknown default:
      return "location_unavailable"
    }
  }

  var image: UIImage? {
    switch self {
    case .notDetermined:
      return UIImage.fos_systemImage(withName: "location")
    case .authorizedWhenInUse, .authorizedAlways:
      return UIImage.fos_systemImage(withName: "location.fill")
    case .denied, .restricted:
      return UIImage.fos_systemImage(withName: "location.slash")
    @unknown default:
      return UIImage.fos_systemImage(withName: "location.slash")
    }
  }
}
