import Foundation
import AppKit
import SwiftUI

/// Represents override settings for a specific app
struct AppOverride: Codable, Identifiable, Equatable {
    let id: UUID
    var bundleIdentifier: String
    var appName: String
    var iconPath: String

    /// Override settings
    var styleOverride: IconStyle?
    var intensityOverride: Double?
    var saturationOverride: Double?
    var brightnessOverride: Double?
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        bundleIdentifier: String,
        appName: String,
        iconPath: String,
        styleOverride: IconStyle? = nil,
        intensityOverride: Double? = nil,
        saturationOverride: Double? = nil,
        brightnessOverride: Double? = nil,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
        self.iconPath = iconPath
        self.styleOverride = styleOverride
        self.intensityOverride = intensityOverride
        self.saturationOverride = saturationOverride
        self.brightnessOverride = brightnessOverride
        self.isEnabled = isEnabled
    }

    var hasOverrides: Bool {
        return styleOverride != nil || intensityOverride != nil ||
               saturationOverride != nil || brightnessOverride != nil
    }
}

/// Manages per-app override preferences
@MainActor
class AppPreferencesManager: ObservableObject {
    static let shared = AppPreferencesManager()

    @Published private(set) var appOverrides: [String: AppOverride] = [:]

    private let userDefaultsKey = "appOverrides"

    private init() {
        loadPreferences()
    }

    /// Get override for a specific app
    func getOverride(for bundleIdentifier: String) -> AppOverride? {
        return appOverrides[bundleIdentifier]
    }

    /// Set or update override for an app
    func setOverride(_ override: AppOverride) {
        appOverrides[override.bundleIdentifier] = override
        savePreferences()
    }

    /// Remove override for an app
    func removeOverride(for bundleIdentifier: String) {
        appOverrides.removeValue(forKey: bundleIdentifier)
        savePreferences()
    }

    /// Toggle enabled state for an app
    func toggleEnabled(for bundleIdentifier: String) {
        if var override = appOverrides[bundleIdentifier] {
            override.isEnabled.toggle()
            appOverrides[bundleIdentifier] = override
            savePreferences()
        }
    }

    /// Get effective style for an app (considering overrides)
    func effectiveStyle(for bundleIdentifier: String) -> IconStyle {
        if let override = appOverrides[bundleIdentifier],
           override.isEnabled,
           let style = override.styleOverride {
            return style
        }
        return SystemPreferences.shared.iconStyle
    }

    /// Get effective intensity for an app
    func effectiveIntensity(for bundleIdentifier: String, default defaultValue: Double) -> Double {
        if let override = appOverrides[bundleIdentifier],
           override.isEnabled,
           let intensity = override.intensityOverride {
            return intensity
        }
        return defaultValue
    }

    /// Check if an app has any overrides enabled
    func hasEnabledOverrides(for bundleIdentifier: String) -> Bool {
        if let override = appOverrides[bundleIdentifier] {
            return override.isEnabled && override.hasOverrides
        }
        return false
    }

    /// Get all apps with overrides
    var appsWithOverrides: [AppOverride] {
        return Array(appOverrides.values).sorted { $0.appName < $1.appName }
    }

    /// Import an app for override management
    func importApp(url: URL) -> AppOverride? {
        guard let bundle = Bundle(url: url),
              let bundleIdentifier = bundle.bundleIdentifier,
              let infoPlist = bundle.infoDictionary,
              let appName = infoPlist["CFBundleName"] as? String ?? infoPlist["CFBundleDisplayName"] as? String else {
            return nil
        }

        // Get icon path
        var iconPath = ""
        if let iconFileName = infoPlist["CFBundleIconFile"] as? String {
            var iconFile = iconFileName
            if !iconFile.hasSuffix(".icns") {
                iconFile += ".icns"
            }
            iconPath = url.appendingPathComponent("Contents/Resources/\(iconFile)").path
        }

        let override = AppOverride(
            bundleIdentifier: bundleIdentifier,
            appName: appName,
            iconPath: iconPath
        )

        setOverride(override)
        return override
    }

    // MARK: - Persistence

    private func savePreferences() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(Array(appOverrides.values)) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    private func loadPreferences() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return
        }

        let decoder = JSONDecoder()
        if let decoded = try? decoder.decode([AppOverride].self, from: data) {
            appOverrides = Dictionary(uniqueKeysWithValues: decoded.map { ($0.bundleIdentifier, $0) })
        }
    }

    /// Reset all overrides
    func resetAllOverrides() {
        appOverrides.removeAll()
        savePreferences()
    }

    /// Export overrides to file
    func exportOverrides(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(Array(appOverrides.values))
        try data.write(to: url)
    }

    /// Import overrides from file
    func importOverrides(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode([AppOverride].self, from: data)

        for override in decoded {
            appOverrides[override.bundleIdentifier] = override
        }
        savePreferences()
    }
}

// MARK: - IconStyle Codable Conformance

extension IconStyle: Codable {
    enum CodingKeys: String, CodingKey {
        case rawValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = IconStyle(rawValue: rawValue) ?? .default
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}
