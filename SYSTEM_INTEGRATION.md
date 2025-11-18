# System Integration Guide

Glasser Studio now **automatically syncs** with macOS icon appearance settings! 🎨

## Icon Styles Supported

### 🌞 Default Style
- **Full liquid glass effect** with maximum vibrancy
- Saturation: 130% × intensity
- Brightness: 110% × intensity
- Vibrance: 50% × intensity
- No color overlay

### 🌙 Dark Style
- **Subdued, darker tones** for a sophisticated look
- Saturation: 110% × intensity (reduced)
- Brightness: 95% × intensity (darker)
- Vibrance: 30% × intensity (subtle)
- **15% opacity black overlay** with multiply blend

### ◯ Clear Style
- **Lighter, more transparent** glass effect
- Saturation: 120% × intensity
- Brightness: 115% × intensity (brighter)
- Vibrance: 40% × intensity
- No color overlay

### 🎨 Tinted Style
- **Enhanced for system accent color**
- Saturation: 140% × intensity (maximum)
- Brightness: 105% × intensity
- Vibrance: 60% × intensity (rich)
- **25% opacity accent color overlay** with color blend mode

## How It Works

### 1. System Preference Reading
`SystemPreferences.swift` reads macOS settings:
```swift
// Checks multiple preference keys
- AppleIconStyle
- com.apple.iconappearance
- System accent color (NSColor.controlAccentColor)
- Dark mode state
```

### 2. Filter Adaptation
`IconProcessor.swift` adjusts the 7-filter pipeline:
- **Different saturation/brightness** per style
- **Style-specific vibrance** amounts
- **Color overlay blending** for Dark/Tinted modes

### 3. UI Integration
- **Main window** shows current icon style with indicator
- **Settings panel** displays:
  - Sync status (✓ Synced with macOS)
  - Current style badge (Default/Dark/Clear/Tinted)
  - Accent color preview (for Tinted mode)

## Testing Different Styles

### Change Icon Style in macOS
**macOS Sonoma 14.0+:**
1. Open **System Settings**
2. Go to **Appearance**
3. Under "Icon and widget style", select:
   - Default (colorful)
   - Dark (monochrome)
   - Clear (transparent)
   - Tinted (accent color)

**Earlier macOS versions:**
- May not have all style options
- App will default to "Default" style

### Verify in Glasser Studio
1. Open Glasser Studio app
2. Check status indicator: "Active • [Style Name]"
3. Open Settings → General tab
4. See "System Integration" section with current style

## Filter Pipeline (7 Stages)

All styles apply these filters, adjusted per style:

1. **Color Controls** - Saturation & Brightness
2. **Vibrance** - Selective color enhancement
3. **Gaussian Blur** - Glass texture
4. **Highlight Shadow Adjust** - Glossy shine
5. **Bloom** - Subtle glow
6. **Sharpen Luminance** - Edge definition
7. **Color Tint** (Dark/Tinted only) - Style overlay

## Accent Color Detection

For **Tinted mode**, Glasser Studio reads:
- `NSColor.controlAccentColor` (macOS accent color)
- Folder color preferences (if set)
- Applies 25% opacity color blend

### Supported Accent Colors
- Blue, Purple, Pink, Red, Orange, Yellow, Green, Graphite
- Custom accent colors (macOS 11+)

## Technical Details

### SystemPreferences.swift
- `iconStyle` property - Current icon style
- `accentColor` property - System accent color
- `effectiveTintColor()` - Returns overlay color for style
- `isDarkMode` property - Dark mode detection

### IconProcessor.swift
- `getStyleParameters()` - Returns (saturation, brightness, vibrance) tuple
- `applyTint()` - Applies color overlay with blend modes
- Style-aware filter pipeline

### ContentView.swift
- Icon style indicator with SF Symbols
- Real-time style refresh on processing
- `iconStyleIcon()` helper for UI

### SettingsView.swift
- System integration status display
- Current style badge
- Accent color preview (tinted mode)

## Examples

### Default → Dark
Icons become **more subdued** with darker tones

### Default → Tinted (Blue accent)
Icons get **blue color overlay** blended at 25%

### Clear → Default
Effect becomes **more vibrant** and saturated

## Limitations

- **System icons** may not change (SIP protected)
- **Folder color** preference may not be accessible on all macOS versions
- **Style detection** works best on macOS 14.0+ (Sonoma)

## Completed Enhancements ✨

The following features have been successfully implemented:

- ✅ **Auto-refresh on system style change** - App automatically detects when you change macOS icon appearance settings and prompts to reapply effects
  - Uses DistributedNotificationCenter to monitor system preferences
  - Polls for changes every 5 seconds as fallback
  - Shows alert dialog when style changes

- ✅ **Per-app style overrides** - Customize effects for individual applications
  - Full UI for managing app-specific settings
  - Override icon style, intensity, and other parameters per app
  - Import apps from /Applications or ~/Applications
  - Enable/disable overrides per app

- ✅ **Comprehensive error logging** - Track and debug issues with detailed logs
  - Multiple log levels (DEBUG, INFO, WARNING, ERROR, CRITICAL)
  - File-based logging with automatic rotation
  - Built-in log viewer in Settings
  - Export logs for troubleshooting

- ✅ **Progress tracking** - Detailed status updates during processing
  - Real-time progress bar with percentage
  - Shows currently processing app name
  - Displays count (e.g., "45/127 apps processed")
  - Published properties for reactive UI updates

- ✅ **Icon cache system** - Dramatically faster reprocessing
  - Caches processed icons by style and intensity
  - Automatic cache invalidation when source icons change
  - SHA-256 hashing for cache keys
  - Automatic cleanup when cache exceeds 500MB
  - 30-day cache expiration

## Future Enhancements

Potential improvements:
- [ ] Live preview of different styles
- [ ] Custom style presets
- [ ] Batch processing with cancellation support
- [ ] Undo/redo functionality
- [ ] Performance metrics and monitoring

---

**Status:** ✅ Fully implemented and significantly enhanced!
