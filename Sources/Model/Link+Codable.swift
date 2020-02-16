import Foundation

extension Link {
    enum CodingKeys: String, CodingKey {
        case name = "value", url = "href"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)

        // Links returned by the FOSDEM API are sometimes malformed. Most of the
        // time the issue is caused by some leftover whitespaces at the end of
        // the URL.
        let urlRawString = try container.decode(String.self, forKey: .url)
        let urlString = urlRawString.trimmingCharacters(in: .whitespacesAndNewlines)
        url = URL(string: urlString)
    }
}
