import Foundation
import SwiftUI
import AppKit

/// Represents a custom style preset
struct StylePreset: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var description: String
    var icon: String

    // Effect parameters
    var style: IconStyle
    var intensity: Double
    var saturation: Double
    var brightness: Double

    // Advanced parameters
    var blurRadius: Double?
    var highlightAmount: Double?
    var bloomIntensity: Double?
    var sharpness: Double?

    // Metadata
    var createdDate: Date
    var modifiedDate: Date
    var isBuiltIn: Bool
    var author: String?

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        icon: String = "star.fill",
        style: IconStyle = .default,
        intensity: Double = 0.8,
        saturation: Double = 1.3,
        brightness: Double = 1.1,
        blurRadius: Double? = nil,
        highlightAmount: Double? = nil,
        bloomIntensity: Double? = nil,
        sharpness: Double? = nil,
        createdDate: Date = Date(),
        modifiedDate: Date = Date(),
        isBuiltIn: Bool = false,
        author: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.style = style
        self.intensity = intensity
        self.saturation = saturation
        self.brightness = brightness
        self.blurRadius = blurRadius
        self.highlightAmount = highlightAmount
        self.bloomIntensity = bloomIntensity
        self.sharpness = sharpness
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
        self.isBuiltIn = isBuiltIn
        self.author = author
    }

    mutating func touch() {
        modifiedDate = Date()
    }
}

/// Manages style presets
@MainActor
class StylePresetsManager: ObservableObject {
    static let shared = StylePresetsManager()

    @Published private(set) var presets: [StylePreset] = []
    @Published var selectedPreset: StylePreset?

    private let userDefaultsKey = "stylePresets"
    private let logger = Logger.shared

    private init() {
        loadPresets()
        ensureBuiltInPresets()
        logger.info("StylePresetsManager initialized with \(presets.count) presets", category: "StylePresets")
    }

    // MARK: - Built-in Presets

    private func ensureBuiltInPresets() {
        let builtInPresets = createBuiltInPresets()

        for builtIn in builtInPresets {
            if !presets.contains(where: { $0.name == builtIn.name && $0.isBuiltIn }) {
                presets.append(builtIn)
            }
        }

        savePresets()
    }

    private func createBuiltInPresets() -> [StylePreset] {
        return [
            StylePreset(
                name: "Subtle Glass",
                description: "Light glass effect with minimal processing",
                icon: "circle.dotted",
                style: .clear,
                intensity: 0.5,
                saturation: 1.1,
                brightness: 1.05,
                isBuiltIn: true,
                author: "Glasser Studio"
            ),

            StylePreset(
                name: "Vibrant Pop",
                description: "Maximum color vibrancy and saturation",
                icon: "paintpalette.fill",
                style: .default,
                intensity: 1.0,
                saturation: 1.6,
                brightness: 1.15,
                bloomIntensity: 0.4,
                isBuiltIn: true,
                author: "Glasser Studio"
            ),

            StylePreset(
                name: "Dark Matter",
                description: "Deep, dark tones with subtle highlights",
                icon: "moon.stars.fill",
                style: .dark,
                intensity: 0.9,
                saturation: 1.0,
                brightness: 0.85,
                highlightAmount: 1.5,
                isBuiltIn: true,
                author: "Glasser Studio"
            ),

            StylePreset(
                name: "Crystal Clear",
                description: "Ultra-crisp with enhanced sharpness",
                icon: "sparkles",
                style: .clear,
                intensity: 0.7,
                saturation: 1.2,
                brightness: 1.2,
                sharpness: 0.8,
                isBuiltIn: true,
                author: "Glasser Studio"
            ),

            StylePreset(
                name: "Neon Dreams",
                description: "Intense glow and bloom effects",
                icon: "sparkle",
                style: .tinted,
                intensity: 0.95,
                saturation: 1.5,
                brightness: 1.1,
                bloomIntensity: 0.6,
                highlightAmount: 1.3,
                isBuiltIn: true,
                author: "Glasser Studio"
            ),

            StylePreset(
                name: "Frosted Glass",
                description: "Heavy blur for a frosted appearance",
                icon: "square.on.square.dashed",
                style: .clear,
                intensity: 0.8,
                saturation: 1.15,
                brightness: 1.1,
                blurRadius: 2.0,
                isBuiltIn: true,
                author: "Glasser Studio"
            ),

            StylePreset(
                name: "Retro Classic",
                description: "Nostalgic look with warmer tones",
                icon: "desktopcomputer",
                style: .default,
                intensity: 0.65,
                saturation: 1.25,
                brightness: 1.05,
                isBuiltIn: true,
                author: "Glasser Studio"
            ),

            StylePreset(
                name: "Professional",
                description: "Balanced and suitable for work environments",
                icon: "briefcase.fill",
                style: .clear,
                intensity: 0.6,
                saturation: 1.15,
                brightness: 1.08,
                isBuiltIn: true,
                author: "Glasser Studio"
            )
        ]
    }

    // MARK: - Preset Management

    func createPreset(_ preset: StylePreset) {
        var newPreset = preset
        newPreset.isBuiltIn = false
        presets.append(newPreset)
        savePresets()
        logger.info("Created preset: \(preset.name)", category: "StylePresets")
    }

    func updatePreset(_ preset: StylePreset) {
        if let index = presets.firstIndex(where: { $0.id == preset.id }) {
            var updated = preset
            updated.touch()
            presets[index] = updated
            savePresets()
            logger.info("Updated preset: \(preset.name)", category: "StylePresets")
        }
    }

    func deletePreset(_ preset: StylePreset) {
        guard !preset.isBuiltIn else {
            logger.warning("Cannot delete built-in preset: \(preset.name)", category: "StylePresets")
            return
        }

        presets.removeAll { $0.id == preset.id }
        savePresets()
        logger.info("Deleted preset: \(preset.name)", category: "StylePresets")
    }

    func duplicatePreset(_ preset: StylePreset) -> StylePreset {
        var duplicate = preset
        duplicate.id = UUID()
        duplicate.name = "\(preset.name) Copy"
        duplicate.isBuiltIn = false
        duplicate.createdDate = Date()
        duplicate.modifiedDate = Date()

        presets.append(duplicate)
        savePresets()
        logger.info("Duplicated preset: \(preset.name)", category: "StylePresets")

        return duplicate
    }

    // MARK: - Preset Application

    func applyPreset(_ preset: StylePreset, to manager: IconManager) {
        // Apply preset settings to UserDefaults
        UserDefaults.standard.set(preset.intensity, forKey: "glassIntensity")
        UserDefaults.standard.set(preset.saturation, forKey: "saturationBoost")
        UserDefaults.standard.set(preset.brightness, forKey: "brightnessBoost")

        // Store additional parameters if needed
        if let blur = preset.blurRadius {
            UserDefaults.standard.set(blur, forKey: "blurRadius")
        }
        if let highlight = preset.highlightAmount {
            UserDefaults.standard.set(highlight, forKey: "highlightAmount")
        }
        if let bloom = preset.bloomIntensity {
            UserDefaults.standard.set(bloom, forKey: "bloomIntensity")
        }
        if let sharpness = preset.sharpness {
            UserDefaults.standard.set(sharpness, forKey: "sharpness")
        }

        selectedPreset = preset
        logger.info("Applied preset: \(preset.name)", category: "StylePresets")
    }

    func getCurrentPreset() -> StylePreset {
        let intensity = UserDefaults.standard.double(forKey: "glassIntensity")
        let saturation = UserDefaults.standard.double(forKey: "saturationBoost")
        let brightness = UserDefaults.standard.double(forKey: "brightnessBoost")

        return StylePreset(
            name: "Current Settings",
            description: "Your current configuration",
            style: SystemPreferences.shared.iconStyle,
            intensity: intensity,
            saturation: saturation,
            brightness: brightness
        )
    }

    // MARK: - Import/Export

    func exportPreset(_ preset: StylePreset) -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        guard let data = try? encoder.encode(preset) else {
            logger.error("Failed to encode preset: \(preset.name)", category: "StylePresets")
            return nil
        }

        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "\(preset.name.replacingOccurrences(of: " ", with: "_")).glasserpreset"
        let fileURL = documentsURL.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            logger.info("Exported preset to: \(fileURL.path)", category: "StylePresets")
            return fileURL
        } catch {
            logger.error("Failed to export preset: \(error.localizedDescription)", category: "StylePresets")
            return nil
        }
    }

    func importPreset(from url: URL) -> StylePreset? {
        guard let data = try? Data(contentsOf: url) else {
            logger.error("Failed to read preset file: \(url.path)", category: "StylePresets")
            return nil
        }

        let decoder = JSONDecoder()
        guard var preset = try? decoder.decode(StylePreset.self, from: data) else {
            logger.error("Failed to decode preset file", category: "StylePresets")
            return nil
        }

        // Assign new ID to avoid conflicts
        preset.id = UUID()
        preset.isBuiltIn = false
        preset.createdDate = Date()
        preset.modifiedDate = Date()

        presets.append(preset)
        savePresets()
        logger.info("Imported preset: \(preset.name)", category: "StylePresets")

        return preset
    }

    // MARK: - Persistence

    private func savePresets() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(presets) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    private func loadPresets() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return
        }

        let decoder = JSONDecoder()
        if let decoded = try? decoder.decode([StylePreset].self, from: data) {
            presets = decoded
        }
    }

    // MARK: - Utilities

    var userPresets: [StylePreset] {
        return presets.filter { !$0.isBuiltIn }
    }

    var builtInPresets: [StylePreset] {
        return presets.filter { $0.isBuiltIn }
    }
}

// MARK: - Presets UI

struct StylePresetsView: View {
    @StateObject private var presetsManager = StylePresetsManager.shared
    @StateObject private var iconManager = IconManager.shared
    @State private var selectedPreset: StylePreset?
    @State private var showingEditor = false
    @State private var editingPreset: StylePreset?

    var body: some View {
        HSplitView {
            // Preset list
            VStack(alignment: .leading, spacing: 12) {
                Text("Style Presets")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                // Built-in presets
                VStack(alignment: .leading, spacing: 8) {
                    Text("Built-in")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)

                    ForEach(presetsManager.builtInPresets) { preset in
                        PresetRow(preset: preset, isSelected: selectedPreset?.id == preset.id)
                            .onTapGesture {
                                selectedPreset = preset
                            }
                    }
                }

                if !presetsManager.userPresets.isEmpty {
                    Divider()

                    // User presets
                    VStack(alignment: .leading, spacing: 8) {
                        Text("My Presets")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.tertiary)

                        ForEach(presetsManager.userPresets) { preset in
                            PresetRow(preset: preset, isSelected: selectedPreset?.id == preset.id)
                                .onTapGesture {
                                    selectedPreset = preset
                                }
                                .contextMenu {
                                    Button("Edit") {
                                        editingPreset = preset
                                        showingEditor = true
                                    }
                                    Button("Duplicate") {
                                        selectedPreset = presetsManager.duplicatePreset(preset)
                                    }
                                    Button("Delete", role: .destructive) {
                                        presetsManager.deletePreset(preset)
                                    }
                                }
                        }
                    }
                }

                Spacer()

                Button(action: {
                    editingPreset = presetsManager.getCurrentPreset()
                    showingEditor = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Preset")
                    }
                    .font(.system(size: 12))
                }
                .buttonStyle(.link)
            }
            .padding(16)
            .frame(minWidth: 200, maxWidth: 250)

            // Preview/Details
            if let preset = selectedPreset {
                PresetDetailView(preset: preset) {
                    presetsManager.applyPreset(preset, to: iconManager)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                    Text("Select a preset to view details")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showingEditor) {
            if let preset = editingPreset {
                PresetEditorView(preset: preset) { savedPreset in
                    if let existing = presetsManager.presets.first(where: { $0.id == savedPreset.id }) {
                        presetsManager.updatePreset(savedPreset)
                    } else {
                        presetsManager.createPreset(savedPreset)
                    }
                    selectedPreset = savedPreset
                    showingEditor = false
                }
            }
        }
    }
}

struct PresetRow: View {
    let preset: StylePreset
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: preset.icon)
                .font(.system(size: 12))
                .frame(width: 20)

            Text(preset.name)
                .font(.system(size: 12))
                .lineLimit(1)

            Spacer()

            if preset.isBuiltIn {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.blue)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(6)
    }
}

struct PresetDetailView: View {
    let preset: StylePreset
    let onApply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            HStack(spacing: 16) {
                Image(systemName: preset.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.name)
                        .font(.system(size: 20, weight: .medium))

                    Text(preset.description)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Divider()

            // Parameters
            VStack(alignment: .leading, spacing: 16) {
                ParameterRow(label: "Style", value: preset.style.rawValue)
                ParameterRow(label: "Intensity", value: String(format: "%.0f%%", preset.intensity * 100))
                ParameterRow(label: "Saturation", value: String(format: "%.0f%%", preset.saturation * 100))
                ParameterRow(label: "Brightness", value: String(format: "%.0f%%", preset.brightness * 100))

                if let blur = preset.blurRadius {
                    ParameterRow(label: "Blur Radius", value: String(format: "%.1f", blur))
                }
                if let highlight = preset.highlightAmount {
                    ParameterRow(label: "Highlight", value: String(format: "%.1f", highlight))
                }
                if let bloom = preset.bloomIntensity {
                    ParameterRow(label: "Bloom", value: String(format: "%.1f", bloom))
                }
                if let sharpness = preset.sharpness {
                    ParameterRow(label: "Sharpness", value: String(format: "%.1f", sharpness))
                }
            }

            Spacer()

            // Apply button
            Button(action: onApply) {
                Text("Apply This Preset")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .padding(24)
    }
}

struct ParameterRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
        }
    }
}

struct PresetEditorView: View {
    @State var preset: StylePreset
    let onSave: (StylePreset) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Preset")
                    .font(.system(size: 16, weight: .medium))

                Spacer()

                Button("Cancel") {
                    dismiss()
                }

                Button("Save") {
                    onSave(preset)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            // Editor
            Form {
                TextField("Preset Name", text: $preset.name)
                TextField("Description", text: $preset.description)

                Picker("Style", selection: $preset.style) {
                    Text("Default").tag(IconStyle.default)
                    Text("Dark").tag(IconStyle.dark)
                    Text("Clear").tag(IconStyle.clear)
                    Text("Tinted").tag(IconStyle.tinted)
                }

                Slider(value: $preset.intensity, in: 0.3...1.0) {
                    Text("Intensity: \(Int(preset.intensity * 100))%")
                }

                Slider(value: $preset.saturation, in: 1.0...2.0) {
                    Text("Saturation: \(Int(preset.saturation * 100))%")
                }

                Slider(value: $preset.brightness, in: 0.9...1.3) {
                    Text("Brightness: \(Int(preset.brightness * 100))%")
                }
            }
            .padding()
        }
        .frame(width: 400, height: 400)
    }
}

#Preview {
    StylePresetsView()
}
