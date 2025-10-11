# Glasser Studio - Liquid Glass Icon Effects for macOS

Transform your macOS app icons with beautiful liquid glass effects! Glasser Studio automatically enhances your dock icons with vibrant colors, glossy finishes, and consistent styling.

## ✨ Features

- **System Integration** - Automatically syncs with macOS icon appearance settings
  - Default, Dark, Clear, and Tinted styles
  - Respects system accent color for tinted mode
  - Adapts filter parameters per style
- **Minimal, Beautiful UI** - Clean, modern interface with smooth animations
- **Liquid Glass Effect** - Apply stunning glass-like effects to all your app icons
- **One-Click Toggle** - Simple switch to enable or disable effects
- **Customizable Parameters** - Fine-tune intensity, saturation, and brightness
- **Automatic Backup** - Original icons are safely backed up
- **Instant Restoration** - Return to original icons anytime

## 🚀 Getting Started

### Requirements
- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later (for building)

### Installation

1. Open the project in Xcode:
   ```bash
   cd "/Users/basil_jackson/Documents/glasser studio sweet edition"
   open GlasserApp.xcodeproj
   ```

2. Build and run the app (⌘R)

### Setting Up Permissions

Glasser requires **Full Disk Access** to modify application icons:

1. Open **System Settings** → **Privacy & Security** → **Full Disk Access**
2. Click the **+** button
3. Navigate to and add **Glasser.app**
4. Restart Glasser

## 🎨 Usage

1. **Launch Glasser**
2. **Enable the effect** using the toggle switch
3. **Click "Apply to All Icons"** to process your icons
4. **Wait for completion** - the Dock will refresh automatically

### Customizing Effects

Go to **Settings** (⌘,) to adjust:
- **Glass Intensity**: Control the strength of the glass effect (30-100%)
- **Saturation Boost**: Enhance color vibrancy (100-200%)
- **Brightness Boost**: Adjust icon brightness (90-130%)

## 🔧 Building from Source

```bash
# Navigate to project directory
cd "/Users/basil_jackson/Documents/glasser studio sweet edition"

# Build with Xcode
xcodebuild -scheme GlasserApp -configuration Release

# Or open in Xcode
open GlasserApp.xcodeproj
```

## 📝 How It Works

### System Integration
Glasser Studio automatically reads macOS icon appearance settings:
- **Default Style**: Full liquid glass effect with vibrant colors
- **Dark Style**: Subdued tones with darker overlay (15% opacity)
- **Clear Style**: Lighter, more transparent effect
- **Tinted Style**: Enhanced vibrancy with system accent color overlay (25% opacity)

The app syncs with:
- System icon style preference (Default/Dark/Clear/Tinted)
- System accent color (for Tinted mode)
- Folder color settings

### Filter Pipeline
Glasser Studio uses Core Image filters, adjusted per icon style:
1. **Saturation Enhancement**: Boosts color vibrancy (style-dependent)
2. **Vibrance Filter**: Adds depth to colors
3. **Gaussian Blur**: Creates subtle glass effect
4. **Highlight Adjustment**: Adds glossy shine
5. **Bloom Filter**: Creates subtle glow
6. **Sharpening**: Maintains edge definition
7. **Color Tinting**: Applies style-specific color overlays

## ⚠️ Important Notes

- **Backup**: Original icons are automatically backed up to `~/Library/Application Support/Glasser/Backups/`
- **System Icons**: Some system apps may require disabling System Integrity Protection (not recommended)
- **Third-party Apps**: Works best with applications in `/Applications` and `~/Applications`
- **Reversible**: You can always restore original icons

## 🐛 Troubleshooting

### Icons not changing?
- Ensure Full Disk Access is granted
- Try restarting the Dock manually: `killall Dock`
- Check that the app has write permissions

### Effect too strong?
- Adjust intensity in Settings
- Lower saturation and brightness boosts

### Want to restore originals?
- Toggle off the effect in the main window
- Original icons will be automatically restored

## 🛡️ Privacy & Security

Glasser Studio:
- Only modifies app icon files
- Stores backups locally on your Mac
- Does not collect or transmit any data
- Requires Full Disk Access only for icon modification

## 📄 License

This project is provided as-is for personal use.

## 🙏 Credits

Created with SwiftUI and Core Image for macOS.
