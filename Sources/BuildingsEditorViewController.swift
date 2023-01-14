#if DEBUG

import MapKit
import UIKit

@available(iOS 16.0, *)
final class BuildingsEditorViewController: UIViewController {
  private var annotations: [Annotation] = [] {
    didSet { didChangeAnnotations(from: oldValue, to: annotations) }
  }

  private lazy var mapView: MKMapView = {
    let center = CLLocationCoordinate2D(
      latitude: 50.81356218080725,
      longitude: 4.382498714271662
    )

    let mapView = MKMapView()
    mapView.delegate = self
    mapView.setCenter(center, animated: false)
    mapView.setCameraZoomRange(.init(maxCenterCoordinateDistance: 0), animated: false)
    mapView.register(MKPinAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKPinAnnotationView.reuseIdentifier)
    return mapView
  }()

  private lazy var centerView: UIView = {
    let view = UIView()
    view.backgroundColor = .fos_label
    view.frame.size = .init(width: 1, height: 1)
    return view
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.leftBarButtonItems = [
      .init(primaryAction: .init(title: "Log coordinates") { [weak self] _ in
        self?.didTapLogCoordinates()
      }),
    ]

    navigationItem.rightBarButtonItems = [
      .init(primaryAction: .init(title: "Drop pin") { [weak self] _ in
        self?.didTapDropPin()
      }),
      .init(primaryAction: .init(title: "Remove last pin") { [weak self] _ in
        self?.didTapRemoveLastPin()
      }),
      .init(primaryAction: .init(title: "Toggle overlay") { [weak self] _ in
        self?.didTapToggleOverlay()
      }),
    ]

    view.addSubview(mapView)
    view.addSubview(centerView)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    mapView.frame = view.bounds
    centerView.center.x = view.bounds.midX
    centerView.center.y = view.bounds.midY
  }
}

@available(iOS 16.0, *)
extension BuildingsEditorViewController: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    let renderer = MKPolygonRenderer(overlay: overlay)
    renderer.fillColor = mapView.tintColor.withAlphaComponent(0.3)
    renderer.strokeColor = mapView.tintColor
    renderer.lineWidth = 1
    return renderer
  }

  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    let view = mapView.dequeueReusableAnnotationView(withIdentifier: MKPinAnnotationView.reuseIdentifier, for: annotation) as! MKPinAnnotationView
    view.isDraggable = true
    view.canShowCallout = true
    return view
  }

  func mapView(_: MKMapView, didSelect view: MKAnnotationView) {
    if let annotation = view.annotation {
      annotations.removeAll(where: { $0 === annotation })
    }
  }

  func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
    print(#function, mapView, view, newState, oldState)
  }
}

@available(iOS 16.0, *)
private extension BuildingsEditorViewController {
  private func didChangeAnnotations(from oldValue: [Annotation], to newValue: [Annotation]) {
    let oldAnnotations = Set(oldValue)
    let newAnnotations = Set(newValue)
    for annotation in oldAnnotations.subtracting(newAnnotations) {
      mapView.removeAnnotation(annotation)
    }
    for annotation in newAnnotations.subtracting(oldAnnotations) {
      mapView.addAnnotation(annotation)
    }
  }

  func didTapDropPin() {
    let center = CGPoint(x: mapView.bounds.midX, y: mapView.bounds.midY)
    let centerCoordinate = mapView.convert(center, toCoordinateFrom: mapView)
    let index = annotations.last?.index ?? 0
    let annotation = Annotation(index: index, coordinate: centerCoordinate)
    annotations.append(annotation)
  }

  func didTapRemoveLastPin() {
    if !annotations.isEmpty {
      annotations.removeLast()
    }
  }

  func didTapToggleOverlay() {
    if let overlay = mapView.overlays.first {
      mapView.removeOverlay(overlay)
    } else {
      var coordinates = annotations.map(\.coordinate)
      let polygon = MKPolygon(coordinates: &coordinates, count: coordinates.count)
      mapView.addOverlay(polygon)
    }
  }

  func didTapLogCoordinates() {
    do {
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      let data = try encoder.encode(annotations)
      if let string = String(data: data, encoding: .utf8) {
        print(string)
      }
    } catch {
      dump(error)
    }
  }
}

private final class Annotation: NSObject {
  let index: Int
  let coordinate: CLLocationCoordinate2D
  init(index: Int, coordinate: CLLocationCoordinate2D) {
    self.coordinate = coordinate
    self.index = index
    super.init()
  }
}

extension Annotation: MKAnnotation {
  var title: String? {
    index.description
  }
}

extension Annotation: Encodable {
  enum CodingKeys: String, CodingKey {
    case latitude, longitude
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(coordinate.latitude, forKey: .latitude)
    try container.encode(coordinate.longitude, forKey: .longitude)
  }
}
#endif
