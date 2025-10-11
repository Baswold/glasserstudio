import Foundation
import AppKit

enum IconStyle: String {
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

class SystemPreferences {
    static let shared = SystemPreferences()
    
    private init() {}
    
    /// Get current icon style from system preferences
    var iconStyle: IconStyle {
        return IconStyle.current()
    }
    
    /// Get system accent color
    var accentColor: NSColor {
        return NSColor.controlAccentColor
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
    
    /// Check if appearance is dark mode
    var isDarkMode: Bool {
        let appearance = NSApp.effectiveAppearance
        let appearanceName = appearance.bestMatch(from: [.darkAqua, .aqua])
        return appearanceName == .darkAqua
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
}
