import Foundation
import AppKit
import Combine

enum IconStyle: String, Equatable {
    case `default` = "Default"
    case dark = "Dark"
    case clear = "Clear"
    case tinted = "Tinted"

    static func current() -> IconStyle {
        // Read from system defaults
        let defaults = UserDefaults.standard

        // Check for icon style preference key
        if let styleString = defaults.string(forKey: "AppleIconStyle") {
            switch styleString.lowercased() {
            case "dark":
                return .dark
            case "clear":
                return .clear
            case "tinted":
                return .tinted
            default:
                return .default
            }
        }

        // Try alternate keys for macOS Sonoma+
        if let style = defaults.value(forKey: "com.apple.iconappearance") as? String {
            switch style.lowercased() {
            case "dark":
                return .dark
            case "clear":
                return .clear
            case "tinted":
                return .tinted
            default:
                return .default
            }
        }

        return .default
    }
}

@MainActor
class SystemPreferences: ObservableObject {
    static let shared = SystemPreferences()

    /// Published property that updates when system icon style changes
    @Published private(set) var iconStyle: IconStyle = .default

    /// Published property that updates when system accent color changes
    @Published private(set) var accentColor: NSColor = .controlAccentColor

    /// Published property that updates when dark mode changes
    @Published private(set) var isDarkMode: Bool = false

    /// Notification name posted when system preferences change
    static let didChangeNotification = Notification.Name("SystemPreferencesDidChange")

    private var observers: [Any] = []
    private var defaultsObserver: NSKeyValueObservation?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        updateAllPreferences()
        startObserving()
    }

    deinit {
        stopObserving()
    }

    /// Start observing system preference changes
    func startObserving() {
        let center = DistributedNotificationCenter.default()
        let notificationCenter = NotificationCenter.default

        // Observe appearance changes (dark mode, accent color)
        let appearanceObserver = center.addObserver(
            forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleSystemPreferencesChange()
            }
        }
        observers.append(appearanceObserver)

        // Observe color preferences changes
        let colorObserver = center.addObserver(
            forName: NSNotification.Name("AppleColorPreferencesChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleSystemPreferencesChange()
            }
        }
        observers.append(colorObserver)

        // Observe accent color changes
        let accentColorObserver = center.addObserver(
            forName: NSNotification.Name("AppleAquaColorVariantChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleSystemPreferencesChange()
            }
        }
        observers.append(accentColorObserver)

        // Observe system preference changes (covers icon style changes)
        let prefsObserver = notificationCenter.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleSystemPreferencesChange()
            }
        }
        observers.append(prefsObserver)

        // Observe NSApp appearance changes
        let appObserver = notificationCenter.addObserver(
            forName: NSApplication.didChangeOcclusionStateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateAllPreferences()
            }
        }
        observers.append(appObserver)

        // Poll for changes periodically as a fallback (every 5 seconds)
        Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.checkForChanges()
                }
            }
            .store(in: &cancellables)

        print("✓ SystemPreferences: Started observing system preference changes")
    }

    /// Stop observing system preference changes
    func stopObserving() {
        let center = DistributedNotificationCenter.default()
        let notificationCenter = NotificationCenter.default

        for observer in observers {
            center.removeObserver(observer)
            notificationCenter.removeObserver(observer)
        }
        observers.removeAll()
        cancellables.removeAll()
        defaultsObserver?.invalidate()
        defaultsObserver = nil

        print("✓ SystemPreferences: Stopped observing")
    }

    /// Handle system preference changes
    private func handleSystemPreferencesChange() {
        let oldStyle = iconStyle
        let oldColor = accentColor
        let oldDarkMode = isDarkMode

        updateAllPreferences()

        // Notify if anything changed
        if oldStyle != iconStyle || oldColor != accentColor || oldDarkMode != isDarkMode {
            print("✓ SystemPreferences: Detected change - Style: \(oldStyle) → \(iconStyle), Dark: \(oldDarkMode) → \(isDarkMode)")

            NotificationCenter.default.post(
                name: SystemPreferences.didChangeNotification,
                object: self,
                userInfo: [
                    "oldStyle": oldStyle,
                    "newStyle": iconStyle,
                    "oldDarkMode": oldDarkMode,
                    "newDarkMode": isDarkMode
                ]
            )
        }
    }

    /// Check for changes without triggering notifications (used by timer)
    private func checkForChanges() {
        let oldStyle = iconStyle
        let oldColor = accentColor
        let oldDarkMode = isDarkMode

        updateAllPreferences()

        // Only log significant changes
        if oldStyle != iconStyle {
            print("✓ SystemPreferences: Icon style changed: \(oldStyle) → \(iconStyle)")
        }
    }

    /// Update all preference values from system
    private func updateAllPreferences() {
        iconStyle = IconStyle.current()
        accentColor = NSColor.controlAccentColor

        let appearance = NSApp.effectiveAppearance
        let appearanceName = appearance.bestMatch(from: [.darkAqua, .aqua])
        isDarkMode = appearanceName == .darkAqua
    }

    /// Get folder tint color if set
    var folderColor: NSColor? {
        let defaults = UserDefaults.standard

        // Try to read folder color from system preferences
        if let colorData = defaults.data(forKey: "FolderColor") {
            return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData)
        }

        return nil
    }

    /// Get effective tint color based on icon style
    func effectiveTintColor() -> NSColor? {
        switch iconStyle {
        case .tinted:
            return accentColor
        case .dark:
            return NSColor.black.withAlphaComponent(0.3)
        case .clear:
            return nil
        case .default:
            return nil
        }
    }

    /// Force refresh all preferences (useful for manual refresh)
    func refresh() {
        handleSystemPreferencesChange()
    }
}
