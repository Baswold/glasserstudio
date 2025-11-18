import Foundation
import AppKit
import SwiftUI

@MainActor
class IconManager: ObservableObject {
    static let shared = IconManager()

    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "glasserEnabled")
            if isEnabled {
                Task {
                    _ = await processAllIcons()
                }
            } else {
                Task {
                    _ = await restoreOriginalIcons()
                }
            }
        }
    }

    @Published var processingProgress: Double = 0.0
    @Published var currentlyProcessing: String = ""
    @Published var totalApps: Int = 0
    @Published var processedApps: Int = 0

    private let backupDirectory: URL
    private let processor = IconProcessor.shared
    private let appPreferences = AppPreferencesManager.shared
    private let logger = Logger.shared

    private init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: "glasserEnabled")

        // Create backup directory
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.backupDirectory = appSupport.appendingPathComponent("Glasser/Backups")

        do {
            try FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
            logger.info("Backup directory created at: \(backupDirectory.path)", category: "IconManager")
        } catch {
            logger.error("Failed to create backup directory: \(error.localizedDescription)", category: "IconManager")
        }

        logger.info("IconManager initialized, effect enabled: \(isEnabled)", category: "IconManager")
    }
    
    func requestPermissions() {
        // This will prompt for Full Disk Access if needed
        let _ = FileManager.default.fileExists(atPath: "/Applications")
    }
    
    func processAllIcons() async -> String {
        let apps = findApplications()
        totalApps = apps.count
        processedApps = 0
        var successCount = 0
        var failCount = 0

        logger.info("Starting icon processing for \(apps.count) applications", category: "IconManager")

        for (index, app) in apps.enumerated() {
            currentlyProcessing = app.lastPathComponent
            processingProgress = Double(index) / Double(apps.count)

            logger.debug("Processing \(app.lastPathComponent)", category: "IconManager")

            if await processApplication(app) {
                successCount += 1
            } else {
                failCount += 1
                logger.warning("Failed to process: \(app.lastPathComponent)", category: "IconManager")
            }

            processedApps = index + 1
        }

        processingProgress = 1.0
        currentlyProcessing = ""

        logger.info("Icon processing complete: \(successCount) succeeded, \(failCount) failed", category: "IconManager")

        // Restart Dock to see changes
        restartDock()

        return "Processed \(successCount) icons successfully. \(failCount) failed."
    }
    
    func restoreOriginalIcons() async -> String {
        let apps = findApplications()
        var restoredCount = 0
        
        for app in apps {
            if restoreOriginalIcon(for: app) {
                restoredCount += 1
            }
        }
        
        // Restart Dock to see changes
        restartDock()
        
        return "Restored \(restoredCount) original icons."
    }
    
    private func findApplications() -> [URL] {
        var apps: [URL] = []
        
        let applicationDirectories = [
            "/Applications",
            "/System/Applications",
            "/System/Library/CoreServices",
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path
        ]
        
        for directory in applicationDirectories {
            if let enumerator = FileManager.default.enumerator(atPath: directory) {
                while let file = enumerator.nextObject() as? String {
                    if file.hasSuffix(".app") {
                        let fullPath = (directory as NSString).appendingPathComponent(file)
                        apps.append(URL(fileURLWithPath: fullPath))
                    }
                }
            }
        }
        
        return apps
    }
    
    private func processApplication(_ appURL: URL) async -> Bool {
        guard let iconPath = getIconPath(for: appURL) else {
            logger.error("Could not find icon path for: \(appURL.lastPathComponent)", category: "IconManager")
            return false
        }

        // Get bundle identifier for per-app preferences
        let bundleIdentifier = Bundle(url: appURL)?.bundleIdentifier ?? appURL.lastPathComponent

        // Check if this app should be skipped (per-app override disabled)
        if let override = appPreferences.getOverride(for: bundleIdentifier), !override.isEnabled {
            logger.debug("Skipping \(appURL.lastPathComponent) - disabled in overrides", category: "IconManager")
            return true // Skip but don't count as failure
        }

        // Create backup if it doesn't exist
        let backupPath = backupDirectory.appendingPathComponent(appURL.lastPathComponent + "_" + URL(fileURLWithPath: iconPath).lastPathComponent)

        if !FileManager.default.fileExists(atPath: backupPath.path) {
            do {
                try FileManager.default.copyItem(at: URL(fileURLWithPath: iconPath), to: backupPath)
                logger.debug("Created backup for: \(appURL.lastPathComponent)", category: "IconManager")
            } catch {
                logger.error("Failed to create backup for \(appURL.lastPathComponent): \(error.localizedDescription)", category: "IconManager")
                return false
            }
        }

        // Get effective intensity (from per-app override or default)
        let intensity = appPreferences.effectiveIntensity(for: bundleIdentifier, default: UserDefaults.standard.double(forKey: "glassIntensity"))

        // Get effective style (from per-app override or system)
        let effectiveStyle = appPreferences.effectiveStyle(for: bundleIdentifier)

        logger.debug("Processing \(appURL.lastPathComponent) with style: \(effectiveStyle.rawValue), intensity: \(intensity)", category: "IconManager")

        // Process the icon with app-specific or default settings
        let tempPath = NSTemporaryDirectory() + UUID().uuidString + ".icns"
        let success = processor.processAndSaveIcon(
            inputPath: iconPath,
            outputPath: tempPath,
            intensity: intensity,
            style: effectiveStyle,
            bundleIdentifier: bundleIdentifier
        )

        if success {
            // Replace original icon
            do {
                try FileManager.default.removeItem(atPath: iconPath)
                try FileManager.default.copyItem(atPath: tempPath, toPath: iconPath)
                try FileManager.default.removeItem(atPath: tempPath)

                // Touch the app to update modification date
                touchApplication(appURL)
                logger.debug("Successfully processed: \(appURL.lastPathComponent)", category: "IconManager")
                return true
            } catch {
                logger.error("Failed to replace icon for \(appURL.lastPathComponent): \(error.localizedDescription)", category: "IconManager")
                return false
            }
        }

        logger.error("Processing failed for: \(appURL.lastPathComponent)", category: "IconManager")
        return false
    }
    
    private func restoreOriginalIcon(for appURL: URL) -> Bool {
        guard let iconPath = getIconPath(for: appURL) else {
            return false
        }
        
        let backupPath = backupDirectory.appendingPathComponent(appURL.lastPathComponent + "_" + URL(fileURLWithPath: iconPath).lastPathComponent)
        
        if FileManager.default.fileExists(atPath: backupPath.path) {
            try? FileManager.default.removeItem(atPath: iconPath)
            try? FileManager.default.copyItem(at: backupPath, to: URL(fileURLWithPath: iconPath))
            
            // Touch the app to update modification date
            touchApplication(appURL)
            return true
        }
        
        return false
    }
    
    private func getIconPath(for appURL: URL) -> String? {
        let infoPlistPath = appURL.appendingPathComponent("Contents/Info.plist")
        
        guard let infoDict = NSDictionary(contentsOf: infoPlistPath),
              let iconFileName = infoDict["CFBundleIconFile"] as? String else {
            return nil
        }
        
        var iconFile = iconFileName
        if !iconFile.hasSuffix(".icns") {
            iconFile += ".icns"
        }
        
        let iconPath = appURL.appendingPathComponent("Contents/Resources/\(iconFile)").path
        
        if FileManager.default.fileExists(atPath: iconPath) {
            return iconPath
        }
        
        return nil
    }
    
    private func touchApplication(_ appURL: URL) {
        let now = Date()
        try? FileManager.default.setAttributes([.modificationDate: now], ofItemAtPath: appURL.path)
    }
    
    private func restartDock() {
        let task = Process()
        task.launchPath = "/usr/bin/killall"
        task.arguments = ["Dock"]
        try? task.run()
    }
}
