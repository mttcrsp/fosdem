import UIKit

public final class ScrollImageView: UIScrollView {
  private let imageView = UIImageView()

  public var image: UIImage? {
    didSet { didChangeImage() }
  }

  override public var frame: CGRect {
    didSet { reloadZoomScales() }
  }

  override public init(frame: CGRect) {
    super.init(frame: frame)

    delegate = self
    bouncesZoom = true
    decelerationRate = .fast
    showsVerticalScrollIndicator = false
    showsHorizontalScrollIndicator = false

    let tapAction = #selector(doubleTapped(_:))
    let tapRecognizer = UITapGestureRecognizer(target: self, action: tapAction)
    tapRecognizer.numberOfTapsRequired = 2
    addGestureRecognizer(tapRecognizer)
    addSubview(imageView)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func layoutSubviews() {
    super.layoutSubviews()

    guard bounds.size != .zero else { return }

    var frame = imageView.frame

    if frame.size.width < bounds.size.width {
      frame.origin.x = (bounds.size.width - frame.size.width) / 2
    } else {
      frame.origin.x = 0
    }

    if frame.size.height < bounds.size.height {
      frame.origin.y = (bounds.size.height - frame.size.height) / 2
    } else {
      frame.origin.y = 0
    }

    imageView.frame = frame
  }

  private func didChangeImage() {
    guard let image = image else {
      imageView.image = nil
      return
    }

    imageView.image = image
    imageView.sizeToFit()
    contentSize = image.size
    reloadZoomScales()

    if contentSize.width > bounds.width {
      let offsetX: CGFloat = (contentSize.width - bounds.width) / 2
      let offsetY: CGFloat = 0
      contentOffset = CGPoint(x: offsetX, y: offsetY)
    }
  }

  @objc private func doubleTapped(_ recognizer: UITapGestureRecognizer) {
    if zoomScale > minimumZoomScale {
      return setZoomScale(minimumZoomScale, animated: true)
    }

    let location = recognizer.location(in: recognizer.view)
    let center = imageView.convert(location, from: self)

    var rect = CGRect.zero
    rect.size.width = imageView.frame.width / maximumZoomScale
    rect.size.height = imageView.frame.height / maximumZoomScale
    rect.origin.x = center.x - (rect.width / 2)
    rect.origin.y = center.y - (rect.height / 2)
    zoom(to: rect, animated: true)
  }

  private func reloadZoomScales() {
    guard let image = image else {
      minimumZoomScale = 1
      maximumZoomScale = 1
      zoomScale = 1
      return
    }

    let xScale = bounds.width / (image.size.width + 64)
    let yScale = bounds.height / (image.size.height + 64)
    minimumZoomScale = min(xScale, yScale)
    maximumZoomScale = max(minimumZoomScale * 2, 2)
    zoomScale = minimumZoomScale
  }
}

extension ScrollImageView: UIScrollViewDelegate {
  public func viewForZooming(in _: UIScrollView) -> UIView? {
    imageView
  }

  public func scrollViewDidZoom(_: UIScrollView) {
    setNeedsLayout()
    layoutIfNeeded()
  }
}
