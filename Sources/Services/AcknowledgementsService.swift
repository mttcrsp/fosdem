import Foundation

protocol AcknowledgementsServiceBundle: AnyObject {
    func path(forResource name: String?, ofType ext: String?) -> String?
}

protocol AcknowledgementsServicePlist: AnyObject {
    func dictionary(withContentsOfFile path: String) -> NSDictionary?
}

final class AcknowledgementsService {
    private let bundle: AcknowledgementsServiceBundle
    private let plist: AcknowledgementsServicePlist

    init(bundle: AcknowledgementsServiceBundle = Bundle.main, plist: AcknowledgementsServicePlist = AcknowledgementsServiceDictionary()) {
        self.bundle = bundle
        self.plist = plist
    }

    func loadAcknowledgements() -> [String]? {
        guard let specifiers = preferencesSpecifiers(forResource: "Licenses") else { return [] }

        var acknowledgements: [String] = []
        for specifier in specifiers {
            if let acknowledgement = specifier["Title"] as? String, let _ = specifier["File"] as? String {
                acknowledgements.append(acknowledgement)
            }
        }

        return acknowledgements
    }

    func loadLicense(for acknowledgement: String) -> String? {
        guard let specifiers = preferencesSpecifiers(forResource: acknowledgement) else { return nil }

        for specifier in specifiers {
            if let license = specifier["FooterText"] as? String {
                return license.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return nil
    }

    private func preferencesSpecifiers(forResource resource: String) -> [[String: Any]]? {
        guard let path = bundle.path(forResource: resource, ofType: "plist"), let root = plist.dictionary(withContentsOfFile: path) else { return nil }
        return root["PreferenceSpecifiers"] as? [[String: Any]]
    }
}

extension Bundle: AcknowledgementsServiceBundle {}

final class AcknowledgementsServiceDictionary: AcknowledgementsServicePlist {
    func dictionary(withContentsOfFile path: String) -> NSDictionary? {
        NSDictionary(contentsOfFile: path)
    }
}
