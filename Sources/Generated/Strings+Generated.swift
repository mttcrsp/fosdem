// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// Favorite
  internal static let favorite = L10n.tr("Localizable", "favorite")
  /// Unfavorite
  internal static let unfavorite = L10n.tr("Localizable", "unfavorite")

  internal enum Acknowledgements {
    /// Acknowledgements
    internal static let title = L10n.tr("Localizable", "acknowledgements.title")
  }

  internal enum Agenda {
    /// Starting soon
    internal static let soon = L10n.tr("Localizable", "agenda.soon")
    /// Agenda
    internal static let title = L10n.tr("Localizable", "agenda.title")
    internal enum Empty {
      /// Events you favorite will appear here to allow you to better plan your FOSDEM
      internal static let message = L10n.tr("Localizable", "agenda.empty.message")
      /// No favorite events
      internal static let title = L10n.tr("Localizable", "agenda.empty.title")
    }
  }

  internal enum Attachment {
    /// Audio
    internal static let audio = L10n.tr("Localizable", "attachment.audio")
    /// Paper
    internal static let paper = L10n.tr("Localizable", "attachment.paper")
    /// Slides
    internal static let slides = L10n.tr("Localizable", "attachment.slides")
    /// Video
    internal static let video = L10n.tr("Localizable", "attachment.video")
  }

  internal enum Code {
    /// Contribute on Github
    internal static let title = L10n.tr("Localizable", "code.title")
  }

  internal enum Devrooms {
    /// Developer Rooms
    internal static let title = L10n.tr("Localizable", "devrooms.title")
  }

  internal enum Error {
    /// Ok
    internal static let dismiss = L10n.tr("Localizable", "error.dismiss")
    internal enum Alert {
      /// Something went wrong. Try againg later or check the AppStore for updates.
      internal static let message = L10n.tr("Localizable", "error.alert.message")
      /// An error occurred
      internal static let title = L10n.tr("Localizable", "error.alert.title")
    }

    internal enum Functionality {
      /// Open AppStore
      internal static let action = L10n.tr("Localizable", "error.functionality.action")
      /// Try again later or check the AppStore for updates.
      internal static let message = L10n.tr("Localizable", "error.functionality.message")
      /// Ooops, something went wrong!
      internal static let title = L10n.tr("Localizable", "error.functionality.title")
    }
  }

  internal enum Event {
    /// Add to Agenda
    internal static let add = L10n.tr("Localizable", "event.add")
    /// Attachments
    internal static let attachments = L10n.tr("Localizable", "event.attachments")
    /// %@ minutes
    internal static func duration(_ p1: Any) -> String {
      L10n.tr("Localizable", "event.duration", String(describing: p1))
    }

    /// Play livestream
    internal static let livestream = L10n.tr("Localizable", "event.livestream")
    /// Speakers: %@
    internal static func people(_ p1: Any) -> String {
      L10n.tr("Localizable", "event.people", String(describing: p1))
    }

    /// Remove from Agenda
    internal static let remove = L10n.tr("Localizable", "event.remove")
    /// Room: %@
    internal static func room(_ p1: Any) -> String {
      L10n.tr("Localizable", "event.room", String(describing: p1))
    }

    /// Track: %@
    internal static func track(_ p1: Any) -> String {
      L10n.tr("Localizable", "event.track", String(describing: p1))
    }

    /// on %@
    internal static func weekday(_ p1: Any) -> String {
      L10n.tr("Localizable", "event.weekday", String(describing: p1))
    }

    internal enum Video {
      /// Resume playback
      internal static let at = L10n.tr("Localizable", "event.video.at")
      /// Watch now
      internal static let begin = L10n.tr("Localizable", "event.video.begin")
      /// Watch again
      internal static let end = L10n.tr("Localizable", "event.video.end")
      internal enum Accessibility {
        /// Resume recording
        internal static let at = L10n.tr("Localizable", "event.video.accessibility.at")
        /// Play recording
        internal static let begin = L10n.tr("Localizable", "event.video.accessibility.begin")
        /// Replay recording
        internal static let end = L10n.tr("Localizable", "event.video.accessibility.end")
      }
    }
  }

  internal enum History {
    /// History
    internal static let title = L10n.tr("Localizable", "history.title")
  }

  internal enum Legal {
    /// Legal
    internal static let title = L10n.tr("Localizable", "legal.title")
  }

  internal enum Location {
    /// Open settings
    internal static let confirm = L10n.tr("Localizable", "location.confirm")
    /// Cancel
    internal static let dismiss = L10n.tr("Localizable", "location.dismiss")
    internal enum Message {
      /// You will always be able to renable them later
      internal static let disable = L10n.tr("Localizable", "location.message.disable")
      /// By enabling location services you will be able to see your current position on the map
      internal static let enable = L10n.tr("Localizable", "location.message.enable")
    }

    internal enum Title {
      /// Disable Location services
      internal static let disable = L10n.tr("Localizable", "location.title.disable")
      /// Enable location services
      internal static let enable = L10n.tr("Localizable", "location.title.enable")
    }
  }

  internal enum Map {
    /// Building %@
    internal static func building(_ p1: Any) -> String {
      L10n.tr("Localizable", "map.building", String(describing: p1))
    }

    /// Display my location
    internal static let location = L10n.tr("Localizable", "map.location")
    /// Reset map
    internal static let reset = L10n.tr("Localizable", "map.reset")
    /// Map
    internal static let title = L10n.tr("Localizable", "map.title")
    internal enum Blueprint {
      /// No blueprint available
      internal static let empty = L10n.tr("Localizable", "map.blueprint.empty")
      /// Building %@
      internal static func title(_ p1: Any) -> String {
        L10n.tr("Localizable", "map.blueprint.title", String(describing: p1))
      }
    }

    internal enum Location {
      /// Disable Location services
      internal static let disable = L10n.tr("Localizable", "map.location.disable")
      /// Enable location services
      internal static let enable = L10n.tr("Localizable", "map.location.enable")
    }
  }

  internal enum More {
    /// More
    internal static let title = L10n.tr("Localizable", "more.title")
    internal enum Search {
      /// Search for events
      internal static let prompt = L10n.tr("Localizable", "more.search.prompt")
    }

    internal enum Section {
      /// About
      internal static let about = L10n.tr("Localizable", "more.section.about")
      /// Other
      internal static let other = L10n.tr("Localizable", "more.section.other")
      /// Recent
      internal static let recent = L10n.tr("Localizable", "more.section.recent")
      /// Previous years
      internal static let years = L10n.tr("Localizable", "more.section.years")
    }
  }

  internal enum Recent {
    /// Videos
    internal static let video = L10n.tr("Localizable", "recent.video")
    internal enum Video {
      /// Watched
      internal static let watched = L10n.tr("Localizable", "recent.video.watched")
      /// Watching
      internal static let watching = L10n.tr("Localizable", "recent.video.watching")
      internal enum Empty {
        /// No videos
        internal static let title = L10n.tr("Localizable", "recent.video.empty.title")
        /// Recordings you watched will appear here
        internal static let watched = L10n.tr("Localizable", "recent.video.empty.watched")
        /// Recordings you started watching will appear here
        internal static let watching = L10n.tr("Localizable", "recent.video.empty.watching")
      }
    }
  }

  internal enum Search {
    /// Search
    internal static let title = L10n.tr("Localizable", "search.title")
    internal enum Empty {
      /// Nothing found for "%@"
      internal static func message(_ p1: Any) -> String {
        L10n.tr("Localizable", "search.empty.message", String(describing: p1))
      }

      /// No results
      internal static let title = L10n.tr("Localizable", "search.empty.title")
    }

    internal enum Error {
      /// Sorry, this query is too good. Try with something else.
      internal static let message = L10n.tr("Localizable", "search.error.message")
      /// Ooops, something went wrong
      internal static let title = L10n.tr("Localizable", "search.error.title")
    }

    internal enum Event {
      /// %@ on %@
      internal static func start(_ p1: Any, _ p2: Any) -> String {
        L10n.tr("Localizable", "search.event.start", String(describing: p1), String(describing: p2))
      }
    }

    internal enum Filter {
      /// All tracks
      internal static let all = L10n.tr("Localizable", "search.filter.all")
      /// Cancel
      internal static let cancel = L10n.tr("Localizable", "search.filter.cancel")
      /// Day %d
      internal static func day(_ p1: Int) -> String {
        L10n.tr("Localizable", "search.filter.day", p1)
      }

      /// Your Favorites
      internal static let favorites = L10n.tr("Localizable", "search.filter.favorites")
      /// Filters
      internal static let title = L10n.tr("Localizable", "search.filter.title")
    }
  }

  internal enum Soon {
    /// In the next 30 minutes
    internal static let title = L10n.tr("Localizable", "soon.title")
    internal enum Empty {
      /// No events are starting in the next 30 minutes
      internal static let message = L10n.tr("Localizable", "soon.empty.message")
      /// No events
      internal static let title = L10n.tr("Localizable", "soon.empty.title")
    }
  }

  internal enum Transportation {
    /// Transportation
    internal static let title = L10n.tr("Localizable", "transportation.title")
    internal enum Item {
      /// Open in Apple Maps
      internal static let apple = L10n.tr("Localizable", "transportation.item.apple")
      /// By bus and/or tram
      internal static let bus = L10n.tr("Localizable", "transportation.item.bus")
      /// By car
      internal static let car = L10n.tr("Localizable", "transportation.item.car")
      /// Open in Google Maps
      internal static let google = L10n.tr("Localizable", "transportation.item.google")
      /// By plane
      internal static let plane = L10n.tr("Localizable", "transportation.item.plane")
      /// Free shuttle buses
      internal static let shuttle = L10n.tr("Localizable", "transportation.item.shuttle")
      /// By taxi
      internal static let taxi = L10n.tr("Localizable", "transportation.item.taxi")
      /// By train
      internal static let train = L10n.tr("Localizable", "transportation.item.train")
    }

    internal enum Section {
      /// Travelling by
      internal static let by = L10n.tr("Localizable", "transportation.section.by")
      /// Directions
      internal static let directions = L10n.tr("Localizable", "transportation.section.directions")
    }
  }

  internal enum Update {
    /// Update
    internal static let confirm = L10n.tr("Localizable", "update.confirm")
    /// Cancel
    internal static let dismiss = L10n.tr("Localizable", "update.dismiss")
    /// A new version of this app is available. Update now to get access to the latests features, data and bug fixes.
    internal static let message = L10n.tr("Localizable", "update.message")
    /// Update available
    internal static let title = L10n.tr("Localizable", "update.title")
  }

  internal enum Welcome {
    /// Continue
    internal static let `continue` = L10n.tr("Localizable", "welcome.continue")
    /// FOSDEM is a free event for software developers to meet, share ideas and collaborate.\n\nEvery year, thousands of developers of free and open source software from all over the world gather at the event in Brussels. In 2021, they will gather online.
    internal static let message = L10n.tr("Localizable", "welcome.message")
    /// FOSDEM %@
    internal static func title(_ p1: Any) -> String {
      L10n.tr("Localizable", "welcome.title", String(describing: p1))
    }
  }

  internal enum Years {
    /// From 2007 to 2021
    internal static let item = L10n.tr("Localizable", "years.item")
    /// Previous years
    internal static let title = L10n.tr("Localizable", "years.title")
    /// FOSDEM %@
    internal static func year(_ p1: Any) -> String {
      L10n.tr("Localizable", "years.year", String(describing: p1))
    }
  }
}

// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
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
