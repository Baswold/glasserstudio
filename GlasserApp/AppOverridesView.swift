import SwiftUI
import AppKit

struct AppOverridesView: View {
    @StateObject private var appPrefsManager = AppPreferencesManager.shared
    @State private var selectedApp: AppOverride?
    @State private var showingAppPicker = false
    @State private var searchText = ""

    var filteredApps: [AppOverride] {
        if searchText.isEmpty {
            return appPrefsManager.appsWithOverrides
        } else {
            return appPrefsManager.appsWithOverrides.filter {
                $0.appName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        HSplitView {
            // App list
            VStack(alignment: .leading, spacing: 12) {
                Text("App Overrides")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 11))
                    TextField("Search apps", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                }
                .padding(8)
                .background(.quaternary.opacity(0.3))
                .cornerRadius(6)

                // App list
                ScrollView {
                    VStack(spacing: 4) {
                        if filteredApps.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "app.dashed")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.tertiary)
                                Text("No app overrides")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                                Button("Add App") {
                                    showingAppPicker = true
                                }
                                .buttonStyle(.link)
                                .font(.system(size: 11))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                        } else {
                            ForEach(filteredApps) { app in
                                AppOverrideRow(app: app, isSelected: selectedApp?.id == app.id)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedApp = app
                                    }
                            }
                        }
                    }
                }

                // Add button
                Button(action: { showingAppPicker = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add App")
                    }
                    .font(.system(size: 12))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderless)
            }
            .padding(16)
            .frame(minWidth: 200, maxWidth: 250)

            // Detail view
            if let selectedApp = selectedApp {
                AppOverrideDetailView(app: Binding(
                    get: { selectedApp },
                    set: { newValue in
                        self.selectedApp = newValue
                        appPrefsManager.setOverride(newValue)
                    }
                ))
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "app.badge.checkmark")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                    Text("Select an app to customize")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .sheet(isPresented: $showingAppPicker) {
            AppPickerView { selectedAppURL in
                if let override = appPrefsManager.importApp(url: selectedAppURL) {
                    selectedApp = override
                }
                showingAppPicker = false
            }
        }
    }
}

struct AppOverrideRow: View {
    let app: AppOverride
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            // App icon (if available)
            if FileManager.default.fileExists(atPath: app.iconPath),
               let image = NSImage(contentsOfFile: app.iconPath) {
                Image(nsImage: image)
                    .resizable()
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: "app")
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(app.appName)
                    .font(.system(size: 12))
                    .lineLimit(1)

                if app.hasOverrides {
                    Text("\(app.overrideCount) override\(app.overrideCount == 1 ? "" : "s")")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if !app.isEnabled {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(6)
    }
}

struct AppOverrideDetailView: View {
    @Binding var app: AppOverride
    @StateObject private var appPrefsManager = AppPreferencesManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack(spacing: 12) {
                    if FileManager.default.fileExists(atPath: app.iconPath),
                       let image = NSImage(contentsOfFile: app.iconPath) {
                        Image(nsImage: image)
                            .resizable()
                            .frame(width: 48, height: 48)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.appName)
                            .font(.system(size: 16, weight: .medium))
                        Text(app.bundleIdentifier)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Toggle("Enabled", isOn: Binding(
                        get: { app.isEnabled },
                        set: { newValue in
                            app.isEnabled = newValue
                            appPrefsManager.setOverride(app)
                        }
                    ))
                    .toggleStyle(.switch)
                }

                Divider()

                // Style Override
                VStack(alignment: .leading, spacing: 12) {
                    Text("Icon Style Override")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Toggle("Use custom style", isOn: Binding(
                        get: { app.styleOverride != nil },
                        set: { enabled in
                            if enabled {
                                app.styleOverride = .default
                            } else {
                                app.styleOverride = nil
                            }
                            appPrefsManager.setOverride(app)
                        }
                    ))
                    .font(.system(size: 12))

                    if app.styleOverride != nil {
                        Picker("Style", selection: Binding(
                            get: { app.styleOverride ?? .default },
                            set: { newValue in
                                app.styleOverride = newValue
                                appPrefsManager.setOverride(app)
                            }
                        )) {
                            Text("Default").tag(IconStyle.default)
                            Text("Dark").tag(IconStyle.dark)
                            Text("Clear").tag(IconStyle.clear)
                            Text("Tinted").tag(IconStyle.tinted)
                        }
                        .pickerStyle(.radioGroup)
                        .font(.system(size: 12))
                    }
                }

                Divider()

                // Intensity Override
                VStack(alignment: .leading, spacing: 12) {
                    Text("Effect Parameters")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Toggle("Custom intensity", isOn: Binding(
                        get: { app.intensityOverride != nil },
                        set: { enabled in
                            if enabled {
                                app.intensityOverride = 0.8
                            } else {
                                app.intensityOverride = nil
                            }
                            appPrefsManager.setOverride(app)
                        }
                    ))
                    .font(.system(size: 12))

                    if app.intensityOverride != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Intensity")
                                    .font(.system(size: 12))
                                Spacer()
                                Text("\(Int((app.intensityOverride ?? 0.8) * 100))%")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            Slider(value: Binding(
                                get: { app.intensityOverride ?? 0.8 },
                                set: { newValue in
                                    app.intensityOverride = newValue
                                    appPrefsManager.setOverride(app)
                                }
                            ), in: 0.3...1.0)
                            .tint(.blue)
                        }
                    }
                }

                Divider()

                // Actions
                VStack(alignment: .leading, spacing: 8) {
                    Button("Remove Override") {
                        appPrefsManager.removeOverride(for: app.bundleIdentifier)
                    }
                    .foregroundColor(.red)
                    .font(.system(size: 12))
                }

                Spacer()
            }
            .padding(24)
        }
    }
}

struct AppPickerView: View {
    let onSelect: (URL) -> Void
    @State private var apps: [URL] = []
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    var filteredApps: [URL] {
        if searchText.isEmpty {
            return apps
        } else {
            return apps.filter {
                $0.lastPathComponent.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Select an App")
                    .font(.system(size: 16, weight: .medium))
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
            }
            .padding()

            Divider()

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search applications", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(12)
            .background(.quaternary.opacity(0.3))
            .padding(.horizontal)
            .padding(.top, 12)

            // App list
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(filteredApps, id: \.self) { appURL in
                        Button(action: { onSelect(appURL) }) {
                            HStack(spacing: 12) {
                                if let bundle = Bundle(url: appURL),
                                   let iconPath = getIconPath(for: bundle),
                                   let image = NSImage(contentsOfFile: iconPath) {
                                    Image(nsImage: image)
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                } else {
                                    Image(systemName: "app")
                                        .frame(width: 32, height: 32)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(appURL.deletingPathExtension().lastPathComponent)
                                        .font(.system(size: 13))
                                    Text(appURL.path)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }

                                Spacer()
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(Color.clear)
                        .onHover { hovering in
                            // Add hover effect if desired
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(width: 500, height: 400)
        .onAppear {
            loadApplications()
        }
    }

    private func loadApplications() {
        var foundApps: [URL] = []

        let directories = [
            "/Applications",
            "/System/Applications",
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path
        ]

        for directory in directories {
            if let enumerator = FileManager.default.enumerator(atPath: directory) {
                while let file = enumerator.nextObject() as? String {
                    if file.hasSuffix(".app") && !file.contains("/") {
                        let fullPath = (directory as NSString).appendingPathComponent(file)
                        foundApps.append(URL(fileURLWithPath: fullPath))
                    }
                }
            }
        }

        apps = foundApps.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private func getIconPath(for bundle: Bundle) -> String? {
        guard let infoPlist = bundle.infoDictionary,
              let iconFileName = infoPlist["CFBundleIconFile"] as? String else {
            return nil
        }

        var iconFile = iconFileName
        if !iconFile.hasSuffix(".icns") {
            iconFile += ".icns"
        }

        return bundle.path(forResource: iconFile.replacingOccurrences(of: ".icns", with: ""), ofType: "icns")
    }
}

// Extension for counting overrides
extension AppOverride {
    var overrideCount: Int {
        var count = 0
        if styleOverride != nil { count += 1 }
        if intensityOverride != nil { count += 1 }
        if saturationOverride != nil { count += 1 }
        if brightnessOverride != nil { count += 1 }
        return count
    }
}

#Preview {
    AppOverridesView()
}
