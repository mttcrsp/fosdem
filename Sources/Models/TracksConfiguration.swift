struct TracksSection {
    var title: String?
    var items: [TracksItem]
}

struct TracksItem {
    var track: Track
    var isLast = false
    var isFirst = false
}

final class TracksConfiguration {
    let sectionForSectionIndexTitle: [String: Int] = [:]
    let sectionIndexTitles: [String] = []
    let sections: [TracksSection] = []

    init(tracks: [Track], favoriteTracks: [Track]) {
        var sections: [TracksSection] = []

        var items: [TracksItem] = []
        for track in favoriteTracks {
            let item = TracksItem(track: track)
            items.append(item)
        }

        if !items.isEmpty {
            items[0].isFirst = true
            items[tracks.count - 1].isLast = true
        }

        let section = TracksSection(title: nil, items: items)
        sections.append(section)

        if !tracks.isEmpty {
            var tracksForInitial: [Character: [Track]] = [:]
            for track in tracks {
                if let initial = track.name.first {
                    tracksForInitial[initial, default: []].append(track)
                }
            }

            let sortedTracksForInitial = tracksForInitial.sorted(by: { lhs, rhs in lhs.key < rhs.key })

            var subsections: [TracksSection] = []
            for (initial, tracks) in sortedTracksForInitial {
                var section = TracksSection(title: String(initial), items: [])

                for track in tracks {
                    let item = TracksItem(track: track)
                    section.items.append(item)
                }

                subsections.append(section)
            }

            if !subsections.isEmpty {
                subsections[0].items[0].isFirst = true
                subsections[subsections.count - 1].items[subsections[subsections.count - 1].items.count - 1].isLast = true
            }

            sections.append(contentsOf: subsections)
        }

        var sectionForSectionIndexTitle: [String: Int] = [:]
        var sectionIndexTitles: [String] = []

        for (index, section) in sections.enumerated() {
            if let title = section.title {
                sectionIndexTitles.append(title)
                sectionForSectionIndexTitle[title] = index
            }
        }

        self.sections = sections
        self.sectionIndexTitles = sectionIndexTitles
        self.sectionForSectionIndexTitle = sectionForSectionIndexTitle
    }
}
