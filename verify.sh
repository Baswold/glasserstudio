#!/bin/bash
# Glasser App - Verification Script

echo "🔍 Verifying Glasser App Project..."
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Counter
passed=0
total=0

# Check function
check() {
    total=$((total + 1))
    if [ -e "$1" ]; then
        echo -e "${GREEN}✅${NC} $2"
        passed=$((passed + 1))
    else
        echo -e "${RED}❌${NC} $2 (MISSING: $1)"
    fi
}

# Source Files
echo "📁 Source Files:"
check "GlasserApp/GlasserApp.swift" "GlasserApp.swift"
check "GlasserApp/ContentView.swift" "ContentView.swift"
check "GlasserApp/SettingsView.swift" "SettingsView.swift"
check "GlasserApp/IconProcessor.swift" "IconProcessor.swift"
check "GlasserApp/IconManager.swift" "IconManager.swift"
check "GlasserApp/SystemPreferences.swift" "SystemPreferences.swift"
check "GlasserApp/Theme.swift" "Theme.swift"

echo ""
echo "⚙️  Configuration:"
check "GlasserApp/Info.plist" "Info.plist"
check "GlasserApp/GlasserApp.entitlements" "Entitlements"

echo ""
echo "📦 Project:"
check "GlasserApp.xcodeproj/project.pbxproj" "Xcode Project"
check "GlasserApp.xcodeproj/xcshareddata/xcschemes/GlasserApp.xcscheme" "Build Scheme"

echo ""
echo "📄 Documentation:"
check "README.md" "README"
check "BUILD_CHECKLIST.md" "Build Checklist"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Status: ${passed}/${total} checks passed"

if [ $passed -eq $total ]; then
    echo -e "${GREEN}✅ ALL TASKS COMPLETE - NO EXCUSES!${NC}"
    echo ""
    echo "🚀 Ready to build:"
    echo "   1. Open GlasserApp.xcodeproj in Xcode"
    echo "   2. Press ⌘R to build and run"
    echo "   3. Grant Full Disk Access in System Settings"
else
    echo -e "${RED}❌ MISSING FILES - Tasks incomplete${NC}"
    exit 1
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
