import Foundation

final class AcknowledgementsService {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func loadAcknowledgements() -> [String]? {
        guard let preferencesSpecifiers = loadPreferencesSpecifiers(forResource: "Licenses") else { return [] }

        var acknowledgements: [String] = []
        for object in preferencesSpecifiers {
            if let acknowledgement = object["Title"] as? String, let _ = object["File"] as? String {
                acknowledgements.append(acknowledgement)
            }
        }
        return acknowledgements
    }

    func loadLicense(for acknowledgement: String) -> String? {
        guard let preferencesSpecifiers = loadPreferencesSpecifiers(forResource: acknowledgement) else { return nil }

        for object in preferencesSpecifiers {
            if let license = object["FooterText"] as? String {
                return license.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return nil
    }

    private func loadPreferencesSpecifiers(forResource resource: String) -> [[String: Any]]? {
        guard let path = bundle.path(forResource: resource, ofType: "plist"), let rootObject = NSDictionary(contentsOfFile: path) else { return nil }
        return rootObject["PreferenceSpecifiers"] as? [[String: Any]]
    }
}
