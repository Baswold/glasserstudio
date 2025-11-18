import SwiftUI

struct SettingsView: View {
    @StateObject private var iconManager = IconManager.shared
    @AppStorage("glassIntensity") private var glassIntensity: Double = 0.8
    @AppStorage("saturationBoost") private var saturationBoost: Double = 1.3
    @AppStorage("brightnessBoost") private var brightnessBoost: Double = 1.1
    
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            EffectSettingsView(
                glassIntensity: $glassIntensity,
                saturationBoost: $saturationBoost,
                brightnessBoost: $brightnessBoost
            )
            .tabItem {
                Label("Effects", systemImage: "sparkles")
            }

            AppOverridesView()
                .tabItem {
                    Label("Apps", systemImage: "app.badge.checkmark")
                }

            LogViewerView()
                .tabItem {
                    Label("Logs", systemImage: "doc.text.magnifyingglass")
                }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 600, height: 400)
    }
}

struct GeneralSettingsView: View {
    @StateObject private var iconManager = IconManager.shared
    @StateObject private var systemPrefs = SystemPreferences.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Effect Toggle
            VStack(alignment: .leading, spacing: 12) {
                Text("Effect")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Toggle("Enable Liquid Glass Effect", isOn: $iconManager.isEnabled)
                    .toggleStyle(.switch)
                    .font(.system(size: 13))
            }
            
            Divider()
            
            // System Integration
            VStack(alignment: .leading, spacing: 12) {
                Text("System Integration")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 12))
                    Text("Synced with macOS icon style")
                        .font(.system(size: 13))
                }
                
                HStack(spacing: 8) {
                    Text("Current style:")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: iconStyleIcon(systemPrefs.iconStyle))
                            .font(.system(size: 11))
                        Text(systemPrefs.iconStyle.rawValue)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.quaternary.opacity(0.5))
                    .cornerRadius(6)
                }

                if systemPrefs.iconStyle == .tinted {
                    HStack(spacing: 8) {
                        Text("Tint color:")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)

                        Circle()
                            .fill(Color(nsColor: systemPrefs.accentColor))
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary.opacity(0.2), lineWidth: 0.5)
                            )
                    }
                }
            }
            
            Divider()
            
            // Permissions
            VStack(alignment: .leading, spacing: 12) {
                Text("Permissions")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Text("Requires Full Disk Access to modify app icons")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Button("Open System Settings") {
                    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
                    NSWorkspace.shared.open(url)
                }
                .buttonStyle(.link)
                .font(.system(size: 12))
            }
            
            Spacer()
        }
        .padding(32)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func iconStyleIcon(_ style: IconStyle) -> String {
        switch style {
        case .default: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .clear: return "circle"
        case .tinted: return "paintpalette.fill"
        }
    }
}

struct EffectSettingsView: View {
    @Binding var glassIntensity: Double
    @Binding var saturationBoost: Double
    @Binding var brightnessBoost: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            // Parameters
            VStack(alignment: .leading, spacing: 12) {
                Text("Parameters")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            
            // Sliders
            VStack(alignment: .leading, spacing: 20) {
                SliderControl(
                    title: "Glass Intensity",
                    value: $glassIntensity,
                    range: 0.3...1.0
                )
                
                SliderControl(
                    title: "Saturation",
                    value: $saturationBoost,
                    range: 1.0...2.0
                )
                
                SliderControl(
                    title: "Brightness",
                    value: $brightnessBoost,
                    range: 0.9...1.3
                )
            }
            
            Divider()
                .padding(.vertical, 8)
            
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    glassIntensity = 0.8
                    saturationBoost = 1.3
                    brightnessBoost = 1.1
                }
            }) {
                Text("Reset to Defaults")
                    .font(.system(size: 12))
            }
            .buttonStyle(.link)
            
            Spacer()
        }
        .padding(32)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SliderControl: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 13))
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: $value, in: range)
                .tint(.blue)
        }
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundStyle(.linearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                
                VStack(spacing: 6) {
                    Text("Glasser Studio")
                        .font(.system(size: 24, weight: .light, design: .rounded))
                        .tracking(0.5)
                    
                    Text("Version 1.0.0")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                
                Text("Liquid glass effects for macOS")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}

#Preview {
    SettingsView()
}
