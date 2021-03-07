// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#elseif os(tvOS) || os(watchOS)
import UIKit
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "ImageAsset.Image", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetImageTypeAlias = ImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
internal enum Asset {
  internal enum Assets {}

  internal enum Blueprints {
    internal static let aw = ImageAsset(name: "aw")
    internal static let h1 = ImageAsset(name: "h1")
    internal static let h2 = ImageAsset(name: "h2")
    internal static let j = ImageAsset(name: "j")
    internal static let k11 = ImageAsset(name: "k1-1")
    internal static let k12 = ImageAsset(name: "k1-2")
    internal static let k2 = ImageAsset(name: "k2")
    internal static let k3 = ImageAsset(name: "k3")
    internal static let k4 = ImageAsset(name: "k4")
    internal static let u = ImageAsset(name: "u")
  }

  internal enum Event {
    internal static let arrowDownCircle = ImageAsset(name: "arrow.down.circle")
    internal static let calendarBadgeMinus = ImageAsset(name: "calendar.badge.minus")
    internal static let calendarBadgePlus = ImageAsset(name: "calendar.badge.plus")
    internal static let clockFill = ImageAsset(name: "clock.fill")
    internal static let mappinCircleFill = ImageAsset(name: "mappin.circle.fill")
    internal static let personFill = ImageAsset(name: "person.fill")
  }

  internal enum Map {
    internal static let arrowCounterclockwise = ImageAsset(name: "arrow.counterclockwise")
    internal static let arrowUpLeftAndArrowDownRight = ImageAsset(name: "arrow.up.left.and.arrow.down.right")
    internal static let xmark = ImageAsset(name: "xmark")
  }

  internal enum More {
    internal static let contribute = ImageAsset(name: "contribute")
    internal static let devrooms = ImageAsset(name: "devrooms")
    internal static let document = ImageAsset(name: "document")
    internal static let history = ImageAsset(name: "history")
    internal static let transportation = ImageAsset(name: "transportation")
    internal static let video = ImageAsset(name: "video")
    internal static let years = ImageAsset(name: "years")
  }

  internal enum Search {
    internal static let logo = ImageAsset(name: "logo")
    internal static let starFill = ImageAsset(name: "star.fill")
    internal static let starSlashFill = ImageAsset(name: "star.slash.fill")
  }

  internal enum Tabs {
    internal static let calendar = ImageAsset(name: "calendar")
    internal static let ellipsisCircle = ImageAsset(name: "ellipsis.circle")
    internal static let magnifyingglass = ImageAsset(name: "magnifyingglass")
    internal static let map = ImageAsset(name: "map")
  }
}

// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

internal struct ImageAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Image = UIImage
  #endif

  internal var image: Image {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let name = NSImage.Name(self.name)
    let image = (bundle == .main) ? NSImage(named: name) : bundle.image(forResource: name)
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }
}

internal extension ImageAsset.Image {
  @available(
    macOS,
    deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property"
  )
  convenience init?(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = BundleToken.bundle
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}

// swiftlint:enable convenience_type
