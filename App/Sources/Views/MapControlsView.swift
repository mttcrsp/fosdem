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

  private var backgroundView: UIVisualEffectView?
  private var legacyBackgroundShadowView: UIView?
  private var legacyBackgroundView: UIVisualEffectView?
  private let resetButton = MapControlView()
  private let locationButton = MapControlView()

  override init(frame: CGRect) {
    super.init(frame: frame)

    if #available(iOS 26.0, *) {
      let effect = UIGlassEffect()
      effect.isInteractive = true
      let backgroundView = UIVisualEffectView(effect: effect)
      backgroundView.translatesAutoresizingMaskIntoConstraints = false
      backgroundView.cornerConfiguration = preferredBackgroundCornerConfiguration
      self.backgroundView = backgroundView
      addSubview(backgroundView)
    } else {
      let legacyBackgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
      legacyBackgroundView.translatesAutoresizingMaskIntoConstraints = false
      legacyBackgroundView.layer.cornerRadius = 8
      legacyBackgroundView.layer.masksToBounds = true
      self.legacyBackgroundView = legacyBackgroundView
      addSubview(legacyBackgroundView)

      let legacyBackgroundShadowView = UIView()
      legacyBackgroundShadowView.translatesAutoresizingMaskIntoConstraints = false
      legacyBackgroundShadowView.layer.shadowRadius = 12
      legacyBackgroundShadowView.layer.shadowOpacity = 0.3
      legacyBackgroundShadowView.layer.shadowOffset = .zero
      legacyBackgroundShadowView.layer.shadowColor = UIColor.black.cgColor
      self.legacyBackgroundShadowView = legacyBackgroundShadowView
      addSubview(legacyBackgroundShadowView)
    }

    locationButton.title = authorizationStatus.title
    locationButton.image = CLAuthorizationStatus.notDetermined.image
    locationButton.accessibilityLabel = authorizationStatus.title
    locationButton.accessibilityIdentifier = authorizationStatus.identifier
    locationButton.addTarget(self, action: #selector(didTapLocation), for: .touchUpInside)

    resetButton.accessibilityIdentifier = "reset"
    resetButton.accessibilityLabel = L10n.Map.reset
    resetButton.addTarget(self, action: #selector(didTapReset), for: .touchUpInside)
    resetButton.image = UIImage(systemName: "arrow.counterclockwise")
    resetButton.title = L10n.Map.reset

    let separatorView = UIView()
    separatorView.isHidden = legacyBackgroundView == nil
    separatorView.backgroundColor = .label.withAlphaComponent(0.3)

    let stackView = UIStackView(arrangedSubviews: [resetButton, separatorView, locationButton])
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    addSubview(stackView)

    var constraints: [NSLayoutConstraint] = [
      separatorView.heightAnchor.constraint(equalToConstant: 1 / traitCollection.displayScale),
      stackView.topAnchor.constraint(equalTo: topAnchor),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
    ]

    if let backgroundView = backgroundView ?? legacyBackgroundView {
      constraints.append(contentsOf: [
        backgroundView.topAnchor.constraint(equalTo: topAnchor),
        backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
        backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
        backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
      ])

      if backgroundView == legacyBackgroundView, let legacyBackgroundShadowView {
        constraints.append(contentsOf: [
          legacyBackgroundShadowView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
          legacyBackgroundShadowView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor),
          legacyBackgroundShadowView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
          legacyBackgroundShadowView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
        ])
      }
    }

    NSLayoutConstraint.activate(constraints)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    if let legacyBackgroundView, let legacyBackgroundShadowView {
      legacyBackgroundShadowView.layer.shadowPath = UIBezierPath(
        roundedRect: legacyBackgroundView.bounds,
        cornerRadius: legacyBackgroundView.layer.cornerRadius
      ).cgPath
    }
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if #available(iOS 26.0, *) {
      if traitCollection.fos_hasRegularSizeClasses != previousTraitCollection?.fos_hasRegularSizeClasses {
        backgroundView?.cornerConfiguration = preferredBackgroundCornerConfiguration
      }
    }
  }

  @available(iOS 26.0, *)
  private var preferredBackgroundCornerConfiguration: UICornerConfiguration {
    traitCollection.fos_hasRegularSizeClasses
      ? .corners(radius: .fixed(16))
      : .capsule()
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
      return UIImage(systemName: "location")
    case .authorizedWhenInUse, .authorizedAlways:
      return UIImage(systemName: "location.fill")
    case .denied, .restricted:
      return UIImage(systemName: "location.slash")
    @unknown default:
      return UIImage(systemName: "location.slash")
    }
  }
}
