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
    
    private let backupDirectory: URL
    private let processor = IconProcessor.shared
    
    private init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: "glasserEnabled")
        
        // Create backup directory
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.backupDirectory = appSupport.appendingPathComponent("Glasser/Backups")
        
        try? FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
    }
    
    func requestPermissions() {
        // This will prompt for Full Disk Access if needed
        let _ = FileManager.default.fileExists(atPath: "/Applications")
    }
    
    func processAllIcons() async -> String {
        let apps = findApplications()
        var successCount = 0
        var failCount = 0
        
        for app in apps {
            if await processApplication(app) {
                successCount += 1
            } else {
                failCount += 1
            }
        }
        
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
            return false
        }
        
        // Create backup if it doesn't exist
        let backupPath = backupDirectory.appendingPathComponent(appURL.lastPathComponent + "_" + URL(fileURLWithPath: iconPath).lastPathComponent)
        
        if !FileManager.default.fileExists(atPath: backupPath.path) {
            try? FileManager.default.copyItem(at: URL(fileURLWithPath: iconPath), to: backupPath)
        }
        
        // Process the icon
        let tempPath = NSTemporaryDirectory() + UUID().uuidString + ".icns"
        let success = processor.processAndSaveIcon(inputPath: iconPath, outputPath: tempPath, intensity: 0.8)
        
        if success {
            // Replace original icon
            try? FileManager.default.removeItem(atPath: iconPath)
            try? FileManager.default.copyItem(atPath: tempPath, toPath: iconPath)
            try? FileManager.default.removeItem(atPath: tempPath)
            
            // Touch the app to update modification date
            touchApplication(appURL)
            return true
        }
        
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
