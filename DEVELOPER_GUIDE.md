# Glasser Studio - Developer Guide

This guide is for developers who want to understand, modify, or extend Glasser Studio.

---

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Core Components](#core-components)
3. [Data Flow](#data-flow)
4. [Key Patterns](#key-patterns)
5. [Adding New Features](#adding-new-features)
6. [Testing Strategy](#testing-strategy)
7. [Performance Considerations](#performance-considerations)
8. [Common Tasks](#common-tasks)

---

## Architecture Overview

### High-Level Structure

```
Glasser Studio
├── UI Layer (SwiftUI)
│   ├── ContentView - Main window
│   ├── SettingsView - Settings tabs
│   ├── AppOverridesView - Per-app management
│   ├── StylePresetsView - Preset browser
│   ├── BatchProcessingView - Batch operations
│   └── LogViewerView - Log viewer
│
├── Business Logic Layer
│   ├── IconManager - Icon processing orchestration
│   ├── IconProcessor - Core Image filter pipeline
│   ├── SystemPreferences - macOS integration
│   ├── AppPreferencesManager - Per-app settings
│   ├── StylePresetsManager - Preset management
│   ├── BatchProcessor - Batch operations
│   ├── IconCache - Caching system
│   └── Logger - Logging system
│
└── Data Layer
    ├── UserDefaults - Settings persistence
    ├── FileManager - Backups & cache
    └── JSON - Structured data
```

### Design Principles

1. **Separation of Concerns**
   - UI layer only handles presentation
   - Business logic in manager classes
   - Data persistence abstracted

2. **Single Responsibility**
   - Each class has one clear purpose
   - No god objects
   - Focused, testable components

3. **Dependency Injection Ready**
   - Managers use singleton pattern (easily replaced)
   - Clear interfaces
   - Mock-friendly design

4. **Reactive UI**
   - ObservableObject pattern
   - @Published properties
   - Combine framework integration

---

## Core Components

### IconManager

**Responsibility:** Orchestrates icon processing

**Key Methods:**
```swift
func processAllIcons() async -> String
func restoreOriginalIcons() async -> String
func processApplication(_ appURL: URL) async -> Bool
```

**Published Properties:**
```swift
@Published var isEnabled: Bool
@Published var processingProgress: Double
@Published var currentlyProcessing: String
@Published var totalApps: Int
@Published var processedApps: Int
```

**Integration Points:**
- Uses IconProcessor for actual processing
- Uses AppPreferencesManager for per-app settings
- Uses Logger for logging
- Updates UI via published properties

**Thread Safety:**
- Marked @MainActor
- All UI updates on main thread
- Async processing methods

### IconProcessor

**Responsibility:** Applies Core Image filters

**Key Methods:**
```swift
func applyLiquidGlassEffect(to image: NSImage, intensity: Double, style: IconStyle?) -> NSImage?
func processAndSaveIcon(inputPath: String, outputPath: String, intensity: Double, style: IconStyle?, bundleIdentifier: String?) -> Bool
```

**Filter Pipeline:**
1. Color Controls (saturation & brightness)
2. Vibrance
3. Gaussian Blur
4. Highlight Shadow Adjust
5. Bloom
6. Sharpen Luminance
7. Color Tint (style-specific)

**Caching Integration:**
```swift
// Check cache first
if let cachedImage = cache.getCachedIcon(...) {
    return cachedImage
}

// Process and cache
let processed = applyFilters(...)
cache.cacheIcon(processed, ...)
```

### SystemPreferences

**Responsibility:** Monitor macOS system preferences

**Key Features:**
- DistributedNotificationCenter for system events
- Timer-based polling as fallback
- Published properties for reactive UI
- Equatable IconStyle enum

**Notifications Observed:**
```swift
- AppleInterfaceThemeChangedNotification
- AppleColorPreferencesChangedNotification
- AppleAquaColorVariantChanged
- UserDefaults.didChangeNotification
```

**Thread Safety:**
- @MainActor for UI updates
- Weak self in closures
- Proper observer cleanup

### AppPreferencesManager

**Responsibility:** Manage per-app overrides

**Data Structure:**
```swift
struct AppOverride {
    let bundleIdentifier: String
    var styleOverride: IconStyle?
    var intensityOverride: Double?
    var isEnabled: Bool
}
```

**Key Methods:**
```swift
func getOverride(for bundleIdentifier: String) -> AppOverride?
func setOverride(_ override: AppOverride)
func effectiveStyle(for bundleIdentifier: String) -> IconStyle
```

**Persistence:**
- JSON encoding/decoding
- UserDefaults storage
- Automatic save on changes

### IconCache

**Responsibility:** Cache processed icons for performance

**Cache Strategy:**
- SHA-256 hashing for cache keys
- File-based storage (PNG format)
- Metadata tracking in JSON
- Automatic invalidation on source changes

**Cache Key Generation:**
```swift
func generateCacheKey(bundleIdentifier: String, style: IconStyle, intensity: Double) -> String {
    let data = "\(bundleIdentifier)-\(style.rawValue)-\(intensity)".data(using: .utf8)!
    let hash = SHA256.hash(data: data)
    return hash.compactMap { String(format: "%02x", $0) }.joined()
}
```

**Cleanup Strategy:**
- Max size: 500MB
- Max age: 30 days
- LRU eviction when full

### Logger

**Responsibility:** Comprehensive logging and debugging

**Log Levels:**
```swift
enum LogLevel {
    case debug    // Verbose information
    case info     // General information
    case warning  // Warning conditions
    case error    // Error conditions
    case critical // Critical failures
}
```

**Features:**
- File-based logging with rotation
- In-memory cache (1000 entries)
- Built-in log viewer UI
- Export functionality
- Categorized logging

**Usage:**
```swift
logger.info("Processing started", category: "IconManager")
logger.error("Failed to load image", category: "IconProcessor",
    metadata: ["path": imagePath])
```

### BatchProcessor

**Responsibility:** Batch operations with control

**Task Management:**
```swift
struct BatchTask {
    let apps: [URL]
    var status: BatchTaskStatus
    var progress: Double
    var processedCount: Int
}
```

**Control Flow:**
```swift
// Start batch
await batchProcessor.processBatch(task)

// Pause/Resume
batchProcessor.pause()
batchProcessor.resume()

// Cancel
batchProcessor.cancel()
```

**Features:**
- Cancellation support
- Pause/Resume
- Task history
- Statistics tracking

### StylePresetsManager

**Responsibility:** Manage style presets

**Preset Structure:**
```swift
struct StylePreset {
    var name: String
    var style: IconStyle
    var intensity: Double
    var saturation: Double
    var brightness: Double
    // Advanced parameters...
}
```

**Built-in Presets:**
- 8 professional presets
- Immutable (isBuiltIn flag)
- Cannot be deleted

**Import/Export:**
```swift
func exportPreset(_ preset: StylePreset) -> URL?
func importPreset(from url: URL) -> StylePreset?
```

---

## Data Flow

### Icon Processing Flow

```
User Action (Click "Apply Effect")
    ↓
ContentView.applyEffect()
    ↓
IconManager.processAllIcons()
    ↓
For each app:
    ├→ AppPreferencesManager.effectiveStyle()
    ├→ IconProcessor.processAndSaveIcon()
    │   ├→ IconCache.getCachedIcon() [Cache hit?]
    │   │   ├→ Yes: Return cached
    │   │   └→ No: Continue processing
    │   ├→ applyLiquidGlassEffect()
    │   │   └→ 7-stage filter pipeline
    │   └→ IconCache.cacheIcon()
    └→ Logger.debug()
    ↓
IconManager updates @Published properties
    ↓
UI automatically updates (Combine)
    ↓
Progress bar, status message, etc.
```

### System Preferences Flow

```
User Changes System Setting
    ↓
macOS broadcasts notification
    ↓
DistributedNotificationCenter receives
    ↓
SystemPreferences.handleSystemPreferencesChange()
    ↓
Updates @Published properties
    ↓
Posts SystemPreferences.didChangeNotification
    ↓
ContentView receives notification
    ↓
Shows alert to user
    ↓
User clicks "Reapply Now"
    ↓
Triggers icon processing with new style
```

---

## Key Patterns

### ObservableObject Pattern

Used for reactive UI updates:

```swift
@MainActor
class IconManager: ObservableObject {
    @Published var isEnabled: Bool
    @Published var processingProgress: Double
}

// In View
@StateObject private var iconManager = IconManager.shared
```

**Why:**
- Automatic UI updates
- Type-safe state management
- Combine integration

### Singleton Pattern

Used for managers:

```swift
class IconManager: ObservableObject {
    static let shared = IconManager()
    private init() { }
}
```

**Why:**
- Single source of truth
- Easy access throughout app
- Testable (can be replaced with mock)

### Async/Await

Used for long-running operations:

```swift
func processAllIcons() async -> String {
    // Async work
    for app in apps {
        await processApplication(app)
    }
}
```

**Why:**
- Cleaner than callbacks
- Natural error handling
- Cancellation support

### Weak Self Pattern

Used in closures to prevent retain cycles:

```swift
observer = center.addObserver(...) { [weak self] _ in
    Task { @MainActor [weak self] in
        self?.handleChange()
    }
}
```

**Why:**
- Prevents memory leaks
- Allows deallocation
- Good practice

---

## Adding New Features

### Adding a New Filter

1. **Create filter method in IconProcessor:**

```swift
private func applyMyNewFilter(to image: CIImage, intensity: Double) -> CIImage? {
    guard let filter = CIFilter(name: "CIMyFilter") else { return nil }
    filter.setValue(image, forKey: kCIInputImageKey)
    filter.setValue(intensity, forKey: "inputIntensity")
    return filter.outputImage
}
```

2. **Add to filter pipeline:**

```swift
private func applyFilters(to image: CIImage, intensity: Double, style: IconStyle) -> CIImage? {
    var currentImage = image

    // ... existing filters ...

    // Add your filter
    if let filtered = applyMyNewFilter(to: currentImage, intensity: intensity) {
        currentImage = filtered
    }

    return currentImage
}
```

3. **Add parameter to Settings:**

```swift
@AppStorage("myFilterIntensity") private var myFilterIntensity: Double = 0.5

SliderControl(
    title: "My Filter",
    value: $myFilterIntensity,
    range: 0.0...1.0
)
```

### Adding a New Preset

1. **Add to built-in presets:**

```swift
private func createBuiltInPresets() -> [StylePreset] {
    return [
        // ... existing presets ...

        StylePreset(
            name: "My New Preset",
            description: "Description here",
            icon: "star.fill",
            style: .default,
            intensity: 0.8,
            saturation: 1.3,
            brightness: 1.1,
            isBuiltIn: true,
            author: "Your Name"
        )
    ]
}
```

### Adding a New Settings Tab

1. **Create view file:**

```swift
struct MyNewSettingsView: View {
    var body: some View {
        VStack {
            Text("My New Settings")
        }
    }
}
```

2. **Add to SettingsView:**

```swift
TabView {
    // ... existing tabs ...

    MyNewSettingsView()
        .tabItem {
            Label("My Tab", systemImage: "star")
        }
}
```

### Adding Logging

Add logging to any class:

```swift
class MyClass {
    private let logger = Logger.shared

    func myMethod() {
        logger.info("Method called", category: "MyClass")

        do {
            try somethingRisky()
        } catch {
            logger.error("Operation failed", category: "MyClass",
                metadata: ["error": error.localizedDescription])
        }
    }
}
```

---

## Testing Strategy

### Unit Testing

**Test IconProcessor:**

```swift
class IconProcessorTests: XCTestCase {
    var processor: IconProcessor!

    override func setUp() {
        processor = IconProcessor.shared
    }

    func testApplyLiquidGlassEffect() {
        let testImage = createTestImage()
        let result = processor.applyLiquidGlassEffect(to: testImage, intensity: 0.8)

        XCTAssertNotNil(result)
    }
}
```

**Test AppPreferencesManager:**

```swift
class AppPreferencesTests: XCTestCase {
    func testSetAndGetOverride() {
        let manager = AppPreferencesManager.shared
        let override = AppOverride(
            bundleIdentifier: "com.test.app",
            appName: "Test App",
            iconPath: "/path/to/icon"
        )

        manager.setOverride(override)
        let retrieved = manager.getOverride(for: "com.test.app")

        XCTAssertEqual(retrieved, override)
    }
}
```

### Integration Testing

**Test full processing flow:**

```swift
func testFullProcessingFlow() async {
    let manager = IconManager.shared
    manager.isEnabled = true

    let result = await manager.processAllIcons()

    XCTAssertTrue(result.contains("succeeded"))
}
```

### UI Testing

**Test preset application:**

```swift
func testApplyPreset() throws {
    let app = XCUIApplication()
    app.launch()

    app.buttons["Settings"].tap()
    app.buttons["Presets"].tap()
    app.buttons["Vibrant Pop"].tap()
    app.buttons["Apply This Preset"].tap()

    // Verify preset was applied
    XCTAssertTrue(app.staticTexts["Vibrant Pop"].exists)
}
```

---

## Performance Considerations

### Caching

**When to invalidate cache:**
- Source icon modified
- Cache entry expired (30 days)
- User manually clears cache

**Cache key generation:**
- Must be deterministic
- Include all parameters that affect output
- Fast to compute (SHA-256 is good)

### Memory Management

**Large image processing:**

```swift
func processLargeImage(_ image: NSImage) -> NSImage? {
    autoreleasepool {
        // Image processing here
        return processedImage
    }
}
```

**Why:** Releases memory immediately

### Async Operations

**Don't block main thread:**

```swift
// Good
Task {
    let result = await heavyOperation()
    await MainActor.run {
        updateUI(result)
    }
}

// Bad
let result = heavyOperation()  // Blocks UI!
updateUI(result)
```

### Batch Size

**Optimal batch sizes:**
- Small batches: < 50 apps
- Medium batches: 50-200 apps
- Large batches: 200+ apps

**Consider:**
- Processing time
- User patience
- Memory constraints

---

## Common Tasks

### Adding a New Icon Style

1. **Add to IconStyle enum:**

```swift
enum IconStyle: String {
    case `default` = "Default"
    case dark = "Dark"
    case clear = "Clear"
    case tinted = "Tinted"
    case myNewStyle = "My New Style"  // Add here
}
```

2. **Add parameters:**

```swift
private func getStyleParameters(for style: IconStyle, intensity: Double) -> (...) {
    switch style {
    // ... existing cases ...
    case .myNewStyle:
        return (1.25 * intensity, 1.05 * intensity, 0.45 * intensity)
    }
}
```

3. **Add icon:**

```swift
private func iconStyleIcon(_ style: IconStyle) -> String {
    switch style {
    // ... existing cases ...
    case .myNewStyle:
        return "star.fill"
    }
}
```

### Debugging Processing Issues

1. **Enable verbose logging:**

```swift
logger.minimumLevel = .debug
```

2. **Check logs:**

```swift
// In app: Settings → Logs
// Look for errors in IconManager and IconProcessor categories
```

3. **Test single app:**

```swift
let testApp = URL(fileURLWithPath: "/Applications/Safari.app")
let result = await processApplication(testApp)
print("Result: \(result)")
```

### Profiling Performance

1. **Add timing:**

```swift
let start = Date()
let result = await processAllIcons()
let duration = Date().timeIntervalSince(start)
logger.info("Processing took \(duration)s", category: "Performance")
```

2. **Use Instruments:**
   - Time Profiler for CPU usage
   - Allocations for memory
   - Leaks for retain cycles

---

## Best Practices

### Code Style

1. **Use descriptive names:**

```swift
// Good
func processApplication(_ appURL: URL) -> Bool

// Bad
func proc(_ url: URL) -> Bool
```

2. **Document complex logic:**

```swift
/// Generates a cache key using SHA-256 hashing
/// - Parameters:
///   - bundleIdentifier: App's bundle ID
///   - style: Icon style being applied
///   - intensity: Effect intensity
/// - Returns: 64-character hex string
func generateCacheKey(...) -> String
```

3. **Use guard for early returns:**

```swift
guard let image = NSImage(contentsOfFile: path) else {
    logger.error("Failed to load image", category: "IconProcessor")
    return nil
}
```

### Error Handling

1. **Log errors:**

```swift
do {
    try riskyOperation()
} catch {
    logger.error("Operation failed: \(error)", category: "MyClass")
    throw error
}
```

2. **Provide context:**

```swift
logger.error("Failed to cache icon", category: "IconCache",
    metadata: [
        "bundleId": bundleIdentifier,
        "style": style.rawValue,
        "error": error.localizedDescription
    ])
```

### Performance

1. **Batch UI updates:**

```swift
// Update multiple properties at once
DispatchQueue.main.async {
    self.progress = newProgress
    self.status = newStatus
    self.count = newCount
}
```

2. **Use background threads:**

```swift
Task.detached(priority: .background) {
    let result = await heavyComputation()
    await MainActor.run {
        self.updateUI(result)
    }
}
```

---

## Troubleshooting

### Common Issues

**Issue: UI not updating**

```swift
// Solution: Ensure @MainActor
@MainActor
func updateProgress(_ value: Double) {
    self.progress = value
}
```

**Issue: Memory leaks in observers**

```swift
// Solution: Use weak self
observer = center.addObserver(...) { [weak self] in
    self?.handle()
}
```

**Issue: Cache not working**

```swift
// Check cache key generation
let key = generateCacheKey(...)
logger.debug("Cache key: \(key)", category: "IconCache")
```

---

## Contributing

### Before Submitting PR

1. ✅ All tests pass
2. ✅ Code follows style guide
3. ✅ Documentation updated
4. ✅ Logging added for new features
5. ✅ Performance tested
6. ✅ No memory leaks

### Commit Message Format

```
feat: Add new batch processing feature

- Implement pause/resume functionality
- Add task history tracking
- Create batch management UI

Fixes #123
```

---

## Resources

### Documentation
- [Apple Core Image](https://developer.apple.com/documentation/coreimage)
- [SwiftUI](https://developer.apple.com/documentation/swiftui)
- [Combine Framework](https://developer.apple.com/documentation/combine)

### Tools
- Xcode 15+
- Instruments for profiling
- SF Symbols app

---

**Version:** 1.0.0
**Last Updated:** 2025
**For:** Glasser Studio Developers

Happy coding! 🚀
