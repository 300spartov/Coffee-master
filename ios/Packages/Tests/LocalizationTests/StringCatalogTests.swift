import Foundation
import Testing

/// Guards the string catalogs (`Localizable.xcstrings`) of every module and the app:
/// every key has a Ukrainian and an English value, and every `tr("…")` used in code exists
/// in its module's catalog. Reads source files, so it needs no app or module bundles.
struct StringCatalogTests {
    private static let iosRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent() // LocalizationTests
        .deletingLastPathComponent() // Tests
        .deletingLastPathComponent() // Packages
        .deletingLastPathComponent() // ios

    /// Module source folder → its catalog (paths relative to `ios/`), discovered so a new module
    /// can't be skipped: every package module's `Resources/Localizable.xcstrings`, plus the app's.
    private static let modules: [(sources: String, catalog: String)] = {
        let suffix = "/Resources/Localizable.xcstrings"
        let packageCatalogs = (FileManager.default.enumerator(atPath: iosRoot.appendingPathComponent("Packages/Sources").path)?
            .compactMap { $0 as? String } ?? [])
            .filter { $0.hasSuffix(suffix) }
            .map { "Packages/Sources/" + $0 }
            .sorted()
        return packageCatalogs.map { (String($0.dropLast(suffix.count)), $0) }
            + [("CoffeeMaster", "CoffeeMaster/Localizable.xcstrings")]
    }()

    /// Every catalog whose values must be complete (includes the app's Info.plist strings).
    private static let allCatalogs = modules.map(\.catalog) + ["CoffeeMaster/InfoPlist.xcstrings"]

    private static func catalog(_ path: String) throws -> [String: Any] {
        let data = try Data(contentsOf: iosRoot.appendingPathComponent(path))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        return try #require(json["strings"] as? [String: Any])
    }

    @Test(arguments: allCatalogs)
    func everyKeyIsTranslated(_ catalogPath: String) throws {
        let strings = try Self.catalog(catalogPath)
        #expect(!strings.isEmpty)
        for (key, entry) in strings {
            // Debug-only labels (gallery, previews) are marked "Don't translate" in Xcode.
            if (entry as? [String: Any])?["shouldTranslate"] as? Bool == false { continue }
            let localizations = (entry as? [String: Any])?["localizations"] as? [String: Any] ?? [:]
            for language in ["uk", "en"] {
                let unit = (localizations[language] as? [String: Any])?["stringUnit"] as? [String: Any]
                let value = unit?["value"] as? String ?? ""
                #expect(!value.isEmpty, "\(catalogPath): \"\(key)\" has no \(language) value")
                #expect(unit?["state"] as? String == "translated", "\(catalogPath): \"\(key)\" \(language) isn't translated")
            }
        }
    }

    /// A module that calls `tr(…)` must ship a catalog (otherwise its strings never translate).
    @Test func everyModuleUsingTrHasACatalog() throws {
        let sources = Self.iosRoot.appendingPathComponent("Packages/Sources")
        let helpers = (FileManager.default.enumerator(atPath: sources.path)?.compactMap { $0 as? String } ?? [])
            .filter { $0.hasSuffix("/Localization.swift") }
            .map { "Packages/Sources/" + $0.replacingOccurrences(of: "/Localization.swift", with: "") }
        #expect(!helpers.isEmpty)
        for module in helpers {
            #expect(Self.modules.contains { $0.sources == module }, "\(module) uses tr() but has no Resources/Localizable.xcstrings")
        }
    }

    @Test(arguments: modules.map(\.sources))
    func everyKeyUsedInCodeIsInTheCatalog(_ sourcesPath: String) throws {
        let catalogPath = try #require(Self.modules.first { $0.sources == sourcesPath }?.catalog)
        let keys = Set(try Self.catalog(catalogPath).keys)
        let used = try Self.trKeys(in: Self.iosRoot.appendingPathComponent(sourcesPath))
        #expect(!used.isEmpty, "\(sourcesPath) has no tr(\"…\") calls")

        for key in used {
            // Interpolations become %@ (strings) or %lld (integers) in the catalog.
            let candidates = Self.catalogKeyCandidates(for: key)
            #expect(candidates.contains(where: keys.contains), "\(sourcesPath): missing \"\(key)\" in \(catalogPath)")
        }
    }

    // MARK: - Helpers

    private static func trKeys(in directory: URL) throws -> Set<String> {
        let regex = try NSRegularExpression(pattern: #"\btr\("((?:[^"\\]|\\.)*)""#)
        var keys = Set<String>()
        let files = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil)?
            .compactMap { $0 as? URL }
            .filter { $0.pathExtension == "swift" && !$0.path.contains("/Gallery/") } ?? []
        for file in files {
            let source = try String(contentsOf: file, encoding: .utf8)
            let range = NSRange(source.startIndex..., in: source)
            for match in regex.matches(in: source, range: range) {
                guard let keyRange = Range(match.range(at: 1), in: source) else { continue }
                keys.insert(String(source[keyRange]).replacingOccurrences(of: "\\'", with: "'"))
            }
        }
        return keys
    }

    /// `"Version \(appVersion)"` → `"Version %@"` / `"Version %lld"`.
    private static func catalogKeyCandidates(for key: String) -> [String] {
        guard key.contains("\\(") else { return [key] }
        let pattern = #"\\\((?:[^()]|\([^()]*\))*\)"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let count = regex.numberOfMatches(in: key, range: NSRange(key.startIndex..., in: key))
        let template = regex.stringByReplacingMatches(in: key, range: NSRange(key.startIndex..., in: key), withTemplate: "\u{0}")
        return (0..<(1 << count)).map { mask in
            var result = ""
            var index = 0
            for character in template {
                if character == "\u{0}" {
                    result += (mask >> index) & 1 == 0 ? "%@" : "%lld"
                    index += 1
                } else {
                    result.append(character)
                }
            }
            return result
        }
    }
}
