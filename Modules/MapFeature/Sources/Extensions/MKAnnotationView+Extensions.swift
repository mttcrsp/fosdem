import MapKit

extension MKAnnotationView {
  static var reuseIdentifier: String {
    String(describing: self)
  }
}
