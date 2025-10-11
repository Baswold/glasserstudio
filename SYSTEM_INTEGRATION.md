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

- **Style changes** require re-applying the effect (click "Apply Effect")
- **System icons** may not change (SIP protected)
- **Folder color** preference may not be accessible on all macOS versions
- **Style detection** works best on macOS 14.0+ (Sonoma)

## Future Enhancements

Potential improvements:
- [ ] Auto-refresh on system style change (DistributedNotificationCenter)
- [ ] Per-app style overrides
- [ ] Live preview of different styles
- [ ] Custom style presets

---

**Status:** ✅ Fully implemented and integrated
