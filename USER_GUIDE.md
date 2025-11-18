# Glasser Studio - Complete User Guide

Welcome to Glasser Studio! This guide will help you master all the powerful features of your new icon management powerhouse.

---

## 📚 Table of Contents

1. [Getting Started](#getting-started)
2. [Basic Features](#basic-features)
3. [Advanced Features](#advanced-features)
4. [Style Presets](#style-presets)
5. [Per-App Customization](#per-app-customization)
6. [Batch Processing](#batch-processing)
7. [Troubleshooting](#troubleshooting)
8. [Tips & Tricks](#tips--tricks)

---

## Getting Started

### First-Time Setup

1. **Grant Permissions**
   - Open System Settings → Privacy & Security → Full Disk Access
   - Add Glasser Studio to the list
   - Restart the app

2. **Enable the Effect**
   - Toggle "Liquid Glass" in the main window
   - The effect is now active but not yet applied

3. **Apply to Icons**
   - Click "Apply Effect" button
   - Watch the progress bar as your icons are processed
   - Wait for completion (first time may take a few minutes)

4. **See the Results**
   - Your Dock will automatically refresh
   - Enjoy your beautiful new glass icons!

---

## Basic Features

### Main Window

The main window is your control center:

- **Toggle Switch**: Enable/disable the effect globally
- **Style Indicator**: Shows current macOS icon style (Default/Dark/Clear/Tinted)
- **Apply Button**: Process all icons with current settings
- **Progress Bar**: Real-time processing status
- **Status Messages**: Helpful information about what's happening

### Effect Parameters

Access via Settings → Effects tab:

1. **Glass Intensity** (30-100%)
   - Controls overall effect strength
   - Lower = subtle, Higher = dramatic

2. **Saturation** (100-200%)
   - Color vibrancy
   - Higher = more vibrant colors

3. **Brightness** (90-130%)
   - Overall brightness adjustment
   - Higher = brighter icons

**Tip**: Start with default values, then adjust to taste!

---

## Advanced Features

### Auto-Refresh System Integration

Glasser Studio automatically monitors your macOS settings:

**What it watches:**
- Icon appearance style (Default/Dark/Clear/Tinted)
- System accent color (for Tinted mode)
- Dark mode changes

**What happens when settings change:**
- You'll see an alert notification
- Option to reapply effects with new style
- Or ignore and continue with current settings

**How to use:**
1. Change icon style in System Settings → Appearance
2. Glasser Studio detects the change
3. Click "Reapply Now" in the alert
4. Icons update to match new style

### Icon Cache System

The cache makes reprocessing 10-100x faster!

**How it works:**
- First processing: Normal speed, icons are cached
- Subsequent processing: Lightning fast (uses cache)
- Automatic: No configuration needed

**Cache management:**
- Location: ~/Library/Application Support/Glasser/IconCache
- Max size: 500MB (auto-cleanup)
- Expiration: 30 days
- Invalidation: Automatic when source icons change

**To clear cache:**
1. Settings → General → Cache Management
2. Click "Clear Cache"
3. Next processing will rebuild cache

---

## Style Presets

### Using Built-in Presets

Glasser Studio includes 8 professional presets:

1. **Subtle Glass** 🟢
   - Light glass effect
   - Great for: Professional environments
   - Perfect when: You want subtle enhancement

2. **Vibrant Pop** 🔴
   - Maximum color vibrancy
   - Great for: Creative work, designers
   - Perfect when: You want bold, eye-catching icons

3. **Dark Matter** 🌑
   - Deep, dark tones
   - Great for: Dark mode enthusiasts
   - Perfect when: Working in low-light environments

4. **Crystal Clear** ✨
   - Ultra-crisp with sharpness
   - Great for: Detail-oriented users
   - Perfect when: You need maximum clarity

5. **Neon Dreams** 💫
   - Intense glow and bloom
   - Great for: Night owls, gamers
   - Perfect when: You want futuristic aesthetics

6. **Frosted Glass** ❄️
   - Heavy blur for frosted look
   - Great for: Minimalists
   - Perfect when: You prefer soft, subtle effects

7. **Retro Classic** 📺
   - Nostalgic warmer tones
   - Great for: Vintage aesthetics
   - Perfect when: You miss the old days

8. **Professional** 💼
   - Balanced and suitable for work
   - Great for: Business use
   - Perfect when: You need subtle but effective

**To apply a preset:**
1. Settings → Presets tab
2. Click on any preset to see details
3. Review the parameters
4. Click "Apply This Preset"
5. Close settings and click "Apply Effect"

### Creating Custom Presets

Make your own perfect preset:

1. **Adjust parameters** in Settings → Effects
2. **Settings → Presets** → Click "Create Preset"
3. **Name your preset** (e.g., "My Perfect Look")
4. **Add description** (optional but recommended)
5. **Click Save**

Your preset is now saved and can be applied anytime!

### Sharing Presets

**Export a preset:**
1. Settings → Presets
2. Right-click on your preset
3. Select "Export"
4. Choose save location
5. Share the .glasserpreset file

**Import a preset:**
1. Settings → Presets
2. Click "Import Preset"
3. Select the .glasserpreset file
4. Preset appears in "My Presets"

---

## Per-App Customization

Customize effects for individual apps!

### Adding an App

1. **Settings → Apps tab**
2. **Click "+ Add App"**
3. **Select app from list**
4. **App appears in your override list**

### Customizing an App

1. **Click on the app** in the list
2. **Toggle "Enabled"** to enable custom settings
3. **Choose custom style** (optional)
4. **Adjust custom intensity** (optional)
5. **Changes save automatically**

### Use Cases

**Example 1: Work vs. Personal**
- Safari: Tinted style (work browser)
- Chrome: Default style (personal browser)
- Result: Easy visual distinction!

**Example 2: Intensity Levels**
- Creative apps (Photoshop, Illustrator): High intensity
- Productivity apps (Word, Excel): Low intensity
- System apps: Disabled (keep original)

**Example 3: Dark Mode Lovers**
- All apps: Dark style
- Except messaging apps: Tinted style
- Result: Cohesive dark theme with highlights

### Managing Overrides

**Temporarily disable an app:**
- Toggle "Enabled" off
- App uses global settings
- Override settings preserved

**Remove an override:**
- Right-click on app
- Select "Remove Override"
- App permanently uses global settings

---

## Batch Processing

Process apps in organized groups!

### Batch Types

1. **All Applications**
   - Processes every app on your Mac
   - Use when: Initial setup or major changes

2. **System Applications**
   - Only /System/Applications
   - Use when: Want to update system apps only

3. **User Applications**
   - Only /Applications (non-system)
   - Use when: Leave system apps untouched

4. **Custom Batch**
   - Your own selection of apps
   - Use when: Need specific control

### Starting a Batch

1. **Settings → Batch tab**
2. **Click "Start Batch Task"**
3. **Select batch type**
4. **Processing begins automatically**

### Controlling a Batch

**While processing:**

- **Pause**: Click "Pause" button
  - Processing stops after current app
  - Resume anytime

- **Resume**: Click "Resume" button
  - Processing continues where it left off

- **Cancel**: Click "Cancel" button
  - Stops immediately
  - Already processed icons remain processed

### Batch History

View your processing history:

- **Duration**: How long the batch took
- **Success rate**: How many apps succeeded
- **Average time**: Per-app processing speed
- **Status**: Completed, Cancelled, or Failed

**Use history to:**
- Track processing patterns
- Estimate future batch times
- Identify problematic apps

---

## Troubleshooting

### Icons Not Changing

**Check permissions:**
1. System Settings → Privacy & Security → Full Disk Access
2. Ensure Glasser Studio is in the list
3. Toggle it off and on
4. Restart Glasser Studio

**Try manual Dock restart:**
```bash
killall Dock
```

**Check if app is disabled:**
1. Settings → Apps
2. Look for the app
3. Ensure "Enabled" is on

### Effect Too Strong/Weak

**Adjust parameters:**
1. Settings → Effects
2. Lower intensity for subtle
3. Raise intensity for dramatic

**Try different preset:**
1. Settings → Presets
2. Try "Subtle Glass" or "Professional"

### Some Apps Don't Change

**Possible reasons:**
- System Integrity Protection (SIP) prevents changes
- App doesn't have standard icon structure
- Permissions issue

**Solutions:**
- For system apps: Expected behavior (SIP)
- For third-party apps: Check app in Apps tab
- Grant Full Disk Access again

### Performance Issues

**If processing is slow:**
1. Check cache: Settings → General
2. Ensure cache is enabled
3. First-time processing is always slower
4. Subsequent processing uses cache

**If app is slow:**
1. Check Logs: Settings → Logs
2. Look for errors or warnings
3. Clear cache and retry
4. Restart the app

---

## Tips & Tricks

### Workflow Tips

**Tip 1: Use Presets for Different Contexts**
- Create "Work" preset (subtle, professional)
- Create "Personal" preset (vibrant, fun)
- Switch between them easily

**Tip 2: Batch Processing Strategy**
- Process User Apps first (what you use most)
- Then System Apps if desired
- Use Custom for specific updates

**Tip 3: Per-App Optimization**
- Disable effect for apps you rarely use
- Saves processing time
- Keeps frequently-used apps optimized

### Advanced Techniques

**Technique 1: Style Combinations**
- Use Tinted mode globally
- Override specific apps to Clear
- Creates nice contrast

**Technique 2: Intensity Layering**
- Low intensity globally (50%)
- High intensity for favorite apps (100%)
- Favorites stand out visually

**Technique 3: Seasonal Themes**
- Create "Summer" preset (bright, vibrant)
- Create "Winter" preset (cool, subtle)
- Create "Holiday" preset (festive colors)
- Switch with seasons!

### Keyboard Shortcuts

While Glasser Studio doesn't have custom shortcuts yet, use these:

- `⌘,` - Open Settings
- `⌘Q` - Quit app
- `⌘W` - Close window

### Performance Optimization

**For fastest reprocessing:**
1. Enable cache (it's on by default)
2. Don't change source icons
3. Use batch processing for bulk updates
4. Use per-app overrides to skip apps

**For smallest disk usage:**
1. Clear cache regularly
2. Remove unused presets
3. Export presets before deleting

### Backup Strategy

**Your icons are safe:**
- Originals backed up to: `~/Library/Application Support/Glasser/Backups/`
- Automatic backup before first processing
- Never lost even if you uninstall

**To restore:**
- Toggle effect off
- Original icons automatically restored
- Or manually restore from backup folder

---

## Keyboard Maestro Integration

Automate Glasser Studio with Keyboard Maestro:

**Example: Style Switcher**
```applescript
tell application "Glasser Studio"
    -- Your automation here
end tell
```

---

## Frequently Asked Questions

### Q: Will this slow down my Mac?
**A:** No! Processing only happens when you click "Apply Effect." Once processed, there's zero performance impact.

### Q: Can I undo if I don't like it?
**A:** Yes! Toggle the effect off, and original icons are restored automatically.

### Q: How much disk space does it use?
**A:** Minimal. Backups: ~50-100MB. Cache: Up to 500MB (optional).

### Q: Does it work with all apps?
**A:** Most apps work perfectly. Some system apps are protected by SIP.

### Q: Will it survive macOS updates?
**A:** You may need to reapply after major macOS updates.

### Q: Can I use it with other icon apps?
**A:** Yes, but they may conflict. Use one at a time for best results.

### Q: Is it safe?
**A:** Absolutely! Automatic backups ensure you can always revert.

---

## Getting Help

### Log Files

When something goes wrong:

1. **Settings → Logs**
2. **Find the error** (red entries)
3. **Click to expand** for details
4. **Export logs** if reporting an issue

### Reporting Issues

Include this information:
- macOS version
- Glasser Studio version
- Steps to reproduce
- Error logs (from Logs tab)
- Screenshots if applicable

---

## Conclusion

Congratulations! You now know how to use all of Glasser Studio's powerful features:

✅ Basic icon processing
✅ Style presets
✅ Per-app customization
✅ Batch operations
✅ Troubleshooting
✅ Advanced techniques

**Enjoy your beautiful icons!** 🎨✨

---

## Quick Reference Card

### Common Tasks

| Task | Steps |
|------|-------|
| Apply effect | Toggle on → Click "Apply Effect" |
| Change style | System Settings → Appearance → Icon style |
| Use preset | Settings → Presets → Click preset → Apply |
| Customize app | Settings → Apps → Add app → Configure |
| Batch process | Settings → Batch → Select type → Start |
| View logs | Settings → Logs |
| Clear cache | Settings → General → Clear Cache |
| Restore originals | Toggle effect off |

### Recommended Settings by Use Case

| Use Case | Intensity | Saturation | Brightness | Style |
|----------|-----------|------------|------------|-------|
| Professional | 60% | 115% | 108% | Clear |
| Creative | 100% | 160% | 115% | Default |
| Dark Mode | 90% | 110% | 95% | Dark |
| Minimal | 50% | 110% | 105% | Clear |
| Vibrant | 100% | 180% | 120% | Tinted |

---

**Version:** 1.0.0
**Last Updated:** 2025
**For:** Glasser Studio

Happy icon customizing! 🚀
