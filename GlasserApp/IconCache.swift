import Foundation
import AppKit
import CryptoKit

/// Represents cache metadata for an icon
struct IconCacheEntry: Codable {
    let bundleIdentifier: String
    let iconHash: String
    let style: IconStyle
    let intensity: Double
    let cachedPath: String
    let timestamp: Date
    let originalModificationDate: Date
}

/// High-performance icon caching system
@MainActor
class IconCache: ObservableObject {
    static let shared = IconCache()

    private let cacheDirectory: URL
    private let metadataFile: URL
    private let logger = Logger.shared

    @Published private(set) var cacheSize: Int64 = 0
    @Published private(set) var cacheEntryCount: Int = 0

    private var entries: [String: IconCacheEntry] = [:]
    private let maxCacheSize: Int64 = 500 * 1024 * 1024 // 500 MB
    private let maxCacheAge: TimeInterval = 30 * 24 * 60 * 60 // 30 days

    private init() {
        // Set up cache directory
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        cacheDirectory = appSupport.appendingPathComponent("Glasser/IconCache")
        metadataFile = cacheDirectory.appendingPathComponent("cache-metadata.json")

        // Create cache directory
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Load metadata
        loadMetadata()

        // Calculate cache size
        updateCacheMetrics()

        logger.info("IconCache initialized with \(entries.count) entries", category: "IconCache")
    }

    // MARK: - Cache Operations

    /// Get cached icon if available and valid
    func getCachedIcon(
        for bundleIdentifier: String,
        iconPath: String,
        style: IconStyle,
        intensity: Double
    ) -> NSImage? {
        let cacheKey = generateCacheKey(bundleIdentifier: bundleIdentifier, style: style, intensity: intensity)

        guard let entry = entries[cacheKey] else {
            logger.debug("Cache miss for: \(bundleIdentifier)", category: "IconCache")
            return nil
        }

        // Check if original icon has been modified
        if let attributes = try? FileManager.default.attributesOfItem(atPath: iconPath),
           let modDate = attributes[.modificationDate] as? Date,
           modDate != entry.originalModificationDate {
            logger.debug("Cache invalidated (icon modified): \(bundleIdentifier)", category: "IconCache")
            removeEntry(for: cacheKey)
            return nil
        }

        // Check if cache entry is too old
        if Date().timeIntervalSince(entry.timestamp) > maxCacheAge {
            logger.debug("Cache expired: \(bundleIdentifier)", category: "IconCache")
            removeEntry(for: cacheKey)
            return nil
        }

        // Load cached image
        if let image = NSImage(contentsOfFile: entry.cachedPath) {
            logger.info("Cache hit for: \(bundleIdentifier)", category: "IconCache")
            return image
        } else {
            logger.warning("Cache entry exists but file missing: \(bundleIdentifier)", category: "IconCache")
            removeEntry(for: cacheKey)
            return nil
        }
    }

    /// Store processed icon in cache
    func cacheIcon(
        _ image: NSImage,
        for bundleIdentifier: String,
        iconPath: String,
        style: IconStyle,
        intensity: Double
    ) -> Bool {
        let cacheKey = generateCacheKey(bundleIdentifier: bundleIdentifier, style: style, intensity: intensity)

        // Generate cached file path
        let fileName = "\(cacheKey).png"
        let cachedPath = cacheDirectory.appendingPathComponent(fileName)

        // Save image
        guard saveImage(image, to: cachedPath.path) else {
            logger.error("Failed to save cached icon: \(bundleIdentifier)", category: "IconCache")
            return false
        }

        // Get original modification date
        let modDate: Date
        if let attributes = try? FileManager.default.attributesOfItem(atPath: iconPath),
           let date = attributes[.modificationDate] as? Date {
            modDate = date
        } else {
            modDate = Date()
        }

        // Create cache entry
        let entry = IconCacheEntry(
            bundleIdentifier: bundleIdentifier,
            iconHash: hashIconFile(iconPath),
            style: style,
            intensity: intensity,
            cachedPath: cachedPath.path,
            timestamp: Date(),
            originalModificationDate: modDate
        )

        entries[cacheKey] = entry
        saveMetadata()
        updateCacheMetrics()

        logger.info("Cached icon for: \(bundleIdentifier) (style: \(style.rawValue))", category: "IconCache")

        // Check if cache needs cleanup
        if cacheSize > maxCacheSize {
            performCacheCleanup()
        }

        return true
    }

    /// Invalidate cache for specific app
    func invalidate(bundleIdentifier: String) {
        let keysToRemove = entries.keys.filter { entries[$0]?.bundleIdentifier == bundleIdentifier }

        for key in keysToRemove {
            removeEntry(for: key)
        }

        logger.info("Invalidated cache for: \(bundleIdentifier)", category: "IconCache")
    }

    /// Invalidate cache for specific style
    func invalidate(style: IconStyle) {
        let keysToRemove = entries.keys.filter { entries[$0]?.style == style }

        for key in keysToRemove {
            removeEntry(for: key)
        }

        logger.info("Invalidated cache for style: \(style.rawValue)", category: "IconCache")
    }

    /// Clear entire cache
    func clearCache() {
        // Remove all cached files
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        entries.removeAll()
        saveMetadata()
        updateCacheMetrics()

        logger.info("Cache cleared", category: "IconCache")
    }

    // MARK: - Private Methods

    private func generateCacheKey(bundleIdentifier: String, style: IconStyle, intensity: Double) -> String {
        let data = "\(bundleIdentifier)-\(style.rawValue)-\(intensity)".data(using: .utf8)!
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func hashIconFile(_ path: String) -> String {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return ""
        }
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func saveImage(_ image: NSImage, to path: String) -> Bool {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            return false
        }

        do {
            try pngData.write(to: URL(fileURLWithPath: path))
            return true
        } catch {
            logger.error("Failed to write cached image: \(error.localizedDescription)", category: "IconCache")
            return false
        }
    }

    private func removeEntry(for key: String) {
        guard let entry = entries[key] else { return }

        // Remove file
        try? FileManager.default.removeItem(atPath: entry.cachedPath)

        // Remove from entries
        entries.removeValue(forKey: key)
        saveMetadata()
        updateCacheMetrics()
    }

    private func performCacheCleanup() {
        logger.info("Performing cache cleanup (size: \(formatBytes(cacheSize)))", category: "IconCache")

        // Sort entries by timestamp (oldest first)
        let sortedEntries = entries.sorted { $0.value.timestamp < $1.value.timestamp }

        // Remove oldest 25% of entries
        let entriesToRemove = sortedEntries.prefix(sortedEntries.count / 4)

        for (key, _) in entriesToRemove {
            removeEntry(for: key)
        }

        logger.info("Cache cleanup complete (new size: \(formatBytes(cacheSize)))", category: "IconCache")
    }

    private func updateCacheMetrics() {
        // Calculate total cache size
        var totalSize: Int64 = 0

        for entry in entries.values {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: entry.cachedPath),
               let fileSize = attributes[.size] as? Int64 {
                totalSize += fileSize
            }
        }

        cacheSize = totalSize
        cacheEntryCount = entries.count
    }

    // MARK: - Persistence

    private func loadMetadata() {
        guard let data = try? Data(contentsOf: metadataFile) else {
            return
        }

        let decoder = JSONDecoder()
        if let decoded = try? decoder.decode([IconCacheEntry].self, from: data) {
            entries = Dictionary(uniqueKeysWithValues: decoded.map {
                let key = generateCacheKey(bundleIdentifier: $0.bundleIdentifier, style: $0.style, intensity: $0.intensity)
                return (key, $0)
            })
        }
    }

    private func saveMetadata() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        if let data = try? encoder.encode(Array(entries.values)) {
            try? data.write(to: metadataFile)
        }
    }

    // MARK: - Utilities

    func getCacheStats() -> CacheStats {
        return CacheStats(
            totalSize: cacheSize,
            entryCount: cacheEntryCount,
            hitRate: 0.0, // Would need to track hits/misses to calculate
            oldestEntry: entries.values.map { $0.timestamp }.min(),
            newestEntry: entries.values.map { $0.timestamp }.max()
        )
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct CacheStats {
    let totalSize: Int64
    let entryCount: Int
    let hitRate: Double
    let oldestEntry: Date?
    let newestEntry: Date?

    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSize)
    }
}

// MARK: - Cache Management UI

struct CacheManagementView: View {
    @StateObject private var cache = IconCache.shared
    @State private var stats: CacheStats?

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Cache Management")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            if let stats = stats {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Cache Size:")
                            .font(.system(size: 12))
                        Spacer()
                        Text(stats.formattedSize)
                            .font(.system(size: 12, weight: .medium))
                            .monospacedDigit()
                    }

                    HStack {
                        Text("Cached Icons:")
                            .font(.system(size: 12))
                        Spacer()
                        Text("\(stats.entryCount)")
                            .font(.system(size: 12, weight: .medium))
                            .monospacedDigit()
                    }

                    if let oldest = stats.oldestEntry {
                        HStack {
                            Text("Oldest Entry:")
                                .font(.system(size: 12))
                            Spacer()
                            Text(oldest, style: .relative)
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                }
                .padding()
                .background(.quaternary.opacity(0.3))
                .cornerRadius(8)
            }

            Button("Clear Cache") {
                cache.clearCache()
                refreshStats()
            }
            .buttonStyle(.link)
            .font(.system(size: 12))

            Text("Clearing the cache will free up disk space but icons will need to be reprocessed.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(32)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            refreshStats()
        }
    }

    private func refreshStats() {
        stats = cache.getCacheStats()
    }
}

#Preview {
    CacheManagementView()
}
