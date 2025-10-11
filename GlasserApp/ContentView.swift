import SwiftUI

struct ContentView: View {
    @StateObject private var iconManager = IconManager.shared
    @State private var isProcessing = false
    @State private var statusMessage = ""
    @State private var isHoveringButton = false
    @State private var currentIconStyle = SystemPreferences.shared.iconStyle
    
    var body: some View {
        ZStack {
            // Subtle gradient background
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(nsColor: .windowBackgroundColor).opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Minimal Header
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundStyle(.linearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .padding(.top, 40)
                    
                    Text("Glasser Studio")
                        .font(.system(size: 28, weight: .light, design: .rounded))
                        .tracking(0.5)
                }
                .padding(.bottom, 40)
                
                // Main Content Card
                VStack(spacing: 24) {
                    // Toggle with minimal design
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Liquid Glass")
                                .font(.system(size: 15, weight: .medium))
                            Text("Transform your dock icons")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $iconManager.isEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .scaleEffect(0.8)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    
                    // Status indicator with icon style
                    if iconManager.isEnabled {
                        HStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 6, height: 6)
                                Text("Active")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text("•")
                                .foregroundStyle(.tertiary)
                                .font(.system(size: 8))
                            
                            HStack(spacing: 4) {
                                Image(systemName: iconStyleIcon(currentIconStyle))
                                    .font(.system(size: 10))
                                Text(currentIconStyle.rawValue)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(.secondary)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        .onAppear {
                            currentIconStyle = SystemPreferences.shared.iconStyle
                        }
                    }
                    
                    // Apply Button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            applyEffect()
                        }
                    }) {
                        HStack(spacing: 10) {
                            if isProcessing {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .progressViewStyle(.circular)
                            } else {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            Text(isProcessing ? "Processing" : "Apply Effect")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    iconManager.isEnabled && !isProcessing
                                    ? LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    : LinearGradient(
                                        colors: [.gray.opacity(0.5), .gray.opacity(0.5)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .scaleEffect(isHoveringButton ? 1.02 : 1.0)
                        .shadow(
                            color: iconManager.isEnabled && !isProcessing 
                                ? Color.blue.opacity(0.3) 
                                : Color.clear,
                            radius: 12,
                            y: 4
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!iconManager.isEnabled || isProcessing)
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isHoveringButton = hovering && iconManager.isEnabled && !isProcessing
                        }
                    }
                    
                    // Status message
                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Minimal footer
                Button(action: { openSecuritySettings() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 10))
                        Text("Requires Full Disk Access")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 24)
            }
        }
        .frame(width: 380, height: 480)
    }
    
    private func applyEffect() {
        isProcessing = true
        statusMessage = "Processing icons..."
        
        // Refresh icon style
        currentIconStyle = SystemPreferences.shared.iconStyle
        
        Task {
            let result = await iconManager.processAllIcons()
            await MainActor.run {
                isProcessing = false
                statusMessage = result
            }
        }
    }
    
    private func openSecuritySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(url)
    }
    
    private func iconStyleIcon(_ style: IconStyle) -> String {
        switch style {
        case .default:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        case .clear:
            return "circle"
        case .tinted:
            return "paintpalette.fill"
        }
    }
}

#Preview {
    ContentView()
}
