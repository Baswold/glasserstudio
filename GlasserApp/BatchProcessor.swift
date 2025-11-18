import Foundation
import AppKit
import SwiftUI

/// Represents a batch processing task
struct BatchTask: Identifiable, Equatable {
    let id: UUID
    let apps: [URL]
    let style: IconStyle?
    let intensity: Double
    let name: String
    var status: BatchTaskStatus
    var progress: Double
    var processedCount: Int
    var totalCount: Int
    var startTime: Date?
    var endTime: Date?

    init(
        id: UUID = UUID(),
        apps: [URL],
        style: IconStyle? = nil,
        intensity: Double = 0.8,
        name: String = "Batch Task",
        status: BatchTaskStatus = .pending,
        progress: Double = 0.0,
        processedCount: Int = 0,
        totalCount: Int? = nil
    ) {
        self.id = id
        self.apps = apps
        self.style = style
        self.intensity = intensity
        self.name = name
        self.status = status
        self.progress = progress
        self.processedCount = processedCount
        self.totalCount = totalCount ?? apps.count
    }

    var duration: TimeInterval? {
        guard let start = startTime else { return nil }
        let end = endTime ?? Date()
        return end.timeIntervalSince(start)
    }

    var averageTimePerApp: TimeInterval? {
        guard let duration = duration, processedCount > 0 else { return nil }
        return duration / Double(processedCount)
    }
}

enum BatchTaskStatus: String, Codable {
    case pending = "Pending"
    case running = "Running"
    case paused = "Paused"
    case cancelled = "Cancelled"
    case completed = "Completed"
    case failed = "Failed"
}

/// Batch processing manager with cancellation support
@MainActor
class BatchProcessor: ObservableObject {
    static let shared = BatchProcessor()

    @Published private(set) var currentTask: BatchTask?
    @Published private(set) var taskHistory: [BatchTask] = []
    @Published var isPaused = false

    private var cancellationRequested = false
    private let logger = Logger.shared
    private let iconManager = IconManager.shared
    private let maxHistorySize = 50

    private init() {
        logger.info("BatchProcessor initialized", category: "BatchProcessor")
    }

    // MARK: - Batch Operations

    /// Process a batch of apps
    func processBatch(_ task: BatchTask) async {
        guard currentTask == nil else {
            logger.warning("Cannot start batch - another task is running", category: "BatchProcessor")
            return
        }

        var updatedTask = task
        updatedTask.status = .running
        updatedTask.startTime = Date()
        updatedTask.processedCount = 0
        updatedTask.progress = 0.0

        currentTask = updatedTask
        cancellationRequested = false
        isPaused = false

        logger.info("Starting batch task: \(task.name) with \(task.apps.count) apps", category: "BatchProcessor")

        var successCount = 0
        var failCount = 0

        for (index, appURL) in task.apps.enumerated() {
            // Check for cancellation
            if cancellationRequested {
                logger.info("Batch task cancelled by user", category: "BatchProcessor")
                updatedTask.status = .cancelled
                break
            }

            // Check for pause
            while isPaused && !cancellationRequested {
                updatedTask.status = .paused
                currentTask = updatedTask
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }

            // Resume if we were paused
            if updatedTask.status == .paused && !isPaused {
                updatedTask.status = .running
            }

            // Process the app
            logger.debug("Processing app \(index + 1)/\(task.apps.count): \(appURL.lastPathComponent)", category: "BatchProcessor")

            if await processApp(appURL, style: task.style, intensity: task.intensity) {
                successCount += 1
            } else {
                failCount += 1
            }

            // Update progress
            updatedTask.processedCount = index + 1
            updatedTask.progress = Double(index + 1) / Double(task.apps.count)
            currentTask = updatedTask
        }

        // Finalize task
        updatedTask.endTime = Date()

        if updatedTask.status == .cancelled {
            logger.info("Batch task cancelled: \(successCount) succeeded, \(failCount) failed", category: "BatchProcessor")
        } else {
            updatedTask.status = .completed
            logger.info("Batch task completed: \(successCount) succeeded, \(failCount) failed", category: "BatchProcessor")
        }

        currentTask = updatedTask

        // Add to history
        addToHistory(updatedTask)

        // Clear current task after a delay
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        currentTask = nil
    }

    /// Process a single app within a batch
    private func processApp(_ appURL: URL, style: IconStyle?, intensity: Double) async -> Bool {
        guard let iconPath = getIconPath(for: appURL) else {
            return false
        }

        let bundleIdentifier = Bundle(url: appURL)?.bundleIdentifier ?? appURL.lastPathComponent

        // Create backup if needed
        let backupDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Glasser/Backups")
        let backupPath = backupDirectory.appendingPathComponent(appURL.lastPathComponent + "_" + URL(fileURLWithPath: iconPath).lastPathComponent)

        if !FileManager.default.fileExists(atPath: backupPath.path) {
            try? FileManager.default.copyItem(at: URL(fileURLWithPath: iconPath), to: backupPath)
        }

        // Process the icon
        let tempPath = NSTemporaryDirectory() + UUID().uuidString + ".icns"
        let processor = IconProcessor.shared

        let success = processor.processAndSaveIcon(
            inputPath: iconPath,
            outputPath: tempPath,
            intensity: intensity,
            style: style,
            bundleIdentifier: bundleIdentifier
        )

        if success {
            try? FileManager.default.removeItem(atPath: iconPath)
            try? FileManager.default.copyItem(atPath: tempPath, toPath: iconPath)
            try? FileManager.default.removeItem(atPath: tempPath)

            // Touch the app
            let now = Date()
            try? FileManager.default.setAttributes([.modificationDate: now], ofItemAtPath: appURL.path)

            return true
        }

        return false
    }

    private func getIconPath(for appURL: URL) -> String? {
        let infoPlistPath = appURL.appendingPathComponent("Contents/Info.plist")

        guard let infoDict = NSDictionary(contentsOf: infoPlistPath),
              let iconFileName = infoDict["CFBundleIconFile"] as? String else {
            return nil
        }

        var iconFile = iconFileName
        if !iconFile.hasSuffix(".icns") {
            iconFile += ".icns"
        }

        let iconPath = appURL.appendingPathComponent("Contents/Resources/\(iconFile)").path

        if FileManager.default.fileExists(atPath: iconPath) {
            return iconPath
        }

        return nil
    }

    // MARK: - Cancellation & Control

    /// Cancel the current batch operation
    func cancel() {
        guard currentTask != nil else { return }

        logger.info("Cancellation requested for batch task", category: "BatchProcessor")
        cancellationRequested = true
    }

    /// Pause the current batch operation
    func pause() {
        guard currentTask != nil, !isPaused else { return }

        logger.info("Pausing batch task", category: "BatchProcessor")
        isPaused = true
    }

    /// Resume a paused batch operation
    func resume() {
        guard currentTask != nil, isPaused else { return }

        logger.info("Resuming batch task", category: "BatchProcessor")
        isPaused = false
    }

    // MARK: - History Management

    private func addToHistory(_ task: BatchTask) {
        taskHistory.insert(task, at: 0)

        // Trim history if needed
        if taskHistory.count > maxHistorySize {
            taskHistory = Array(taskHistory.prefix(maxHistorySize))
        }
    }

    func clearHistory() {
        taskHistory.removeAll()
        logger.info("Batch history cleared", category: "BatchProcessor")
    }

    // MARK: - Predefined Batches

    /// Create a batch for all applications
    func createAllAppsBatch() -> BatchTask {
        let apps = findAllApplications()
        return BatchTask(apps: apps, name: "All Applications (\(apps.count) apps)")
    }

    /// Create a batch for system applications only
    func createSystemAppsBatch() -> BatchTask {
        let apps = findAllApplications().filter { $0.path.hasPrefix("/System/Applications") }
        return BatchTask(apps: apps, name: "System Applications (\(apps.count) apps)")
    }

    /// Create a batch for user applications only
    func createUserAppsBatch() -> BatchTask {
        let apps = findAllApplications().filter { $0.path.hasPrefix("/Applications") && !$0.path.hasPrefix("/System") }
        return BatchTask(apps: apps, name: "User Applications (\(apps.count) apps)")
    }

    /// Create a batch from a custom list of apps
    func createCustomBatch(apps: [URL], name: String) -> BatchTask {
        return BatchTask(apps: apps, name: name)
    }

    private func findAllApplications() -> [URL] {
        var apps: [URL] = []

        let directories = [
            "/Applications",
            "/System/Applications",
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path
        ]

        for directory in directories {
            if let enumerator = FileManager.default.enumerator(atPath: directory) {
                while let file = enumerator.nextObject() as? String {
                    if file.hasSuffix(".app") {
                        let fullPath = (directory as NSString).appendingPathComponent(file)
                        apps.append(URL(fileURLWithPath: fullPath))
                    }
                }
            }
        }

        return apps
    }

    // MARK: - Utilities

    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%dh %dm %ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }

    var isProcessing: Bool {
        return currentTask?.status == .running || currentTask?.status == .paused
    }
}

// MARK: - Batch Processing UI

struct BatchProcessingView: View {
    @StateObject private var batchProcessor = BatchProcessor.shared
    @State private var showingBatchSelector = false

    var body: some View {
        VStack(spacing: 0) {
            // Current task
            if let task = batchProcessor.currentTask {
                CurrentTaskView(task: task)
                Divider()
            }

            // Controls
            VStack(spacing: 16) {
                if batchProcessor.currentTask == nil {
                    // Start new batch
                    VStack(spacing: 12) {
                        Text("Batch Processing")
                            .font(.system(size: 16, weight: .medium))

                        Button("Start Batch Task") {
                            showingBatchSelector = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    // Control current batch
                    HStack(spacing: 12) {
                        if batchProcessor.isPaused {
                            Button("Resume") {
                                batchProcessor.resume()
                            }
                        } else {
                            Button("Pause") {
                                batchProcessor.pause()
                            }
                        }

                        Button("Cancel", role: .destructive) {
                            batchProcessor.cancel()
                        }
                    }
                    .padding()
                }

                // History
                if !batchProcessor.taskHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Tasks")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)

                            Spacer()

                            Button("Clear History") {
                                batchProcessor.clearHistory()
                            }
                            .font(.system(size: 11))
                            .buttonStyle(.link)
                        }

                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(batchProcessor.taskHistory) { task in
                                    BatchHistoryRow(task: task)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingBatchSelector) {
            BatchSelectorView { selectedTask in
                Task {
                    await batchProcessor.processBatch(selectedTask)
                }
                showingBatchSelector = false
            }
        }
    }
}

struct CurrentTaskView: View {
    let task: BatchTask

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.name)
                        .font(.system(size: 14, weight: .medium))

                    Text(task.status.rawValue)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let duration = task.duration {
                    Text(BatchProcessor.shared.formatDuration(duration))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            ProgressView(value: task.progress)

            HStack {
                Text("\(task.processedCount)/\(task.totalCount) apps")
                    .font(.system(size: 11))

                Spacer()

                if let avgTime = task.averageTimePerApp {
                    Text(String(format: "%.1fs/app", avgTime))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.quaternary.opacity(0.3))
    }
}

struct BatchHistoryRow: View {
    let task: BatchTask

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.system(size: 12))

                HStack(spacing: 8) {
                    StatusBadge(status: task.status)

                    if let duration = task.duration {
                        Text(BatchProcessor.shared.formatDuration(duration))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            Text("\(task.processedCount)/\(task.totalCount)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(.quaternary.opacity(0.2))
        .cornerRadius(6)
    }
}

struct StatusBadge: View {
    let status: BatchTaskStatus

    var body: some View {
        Text(status.rawValue)
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor)
            .cornerRadius(4)
    }

    var statusColor: Color {
        switch status {
        case .pending: return .gray
        case .running: return .blue
        case .paused: return .orange
        case .cancelled: return .red
        case .completed: return .green
        case .failed: return .red
        }
    }
}

struct BatchSelectorView: View {
    let onSelect: (BatchTask) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var batchProcessor = BatchProcessor.shared

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Select Batch Task")
                    .font(.system(size: 16, weight: .medium))

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
            }
            .padding()

            Divider()

            ScrollView {
                VStack(spacing: 12) {
                    // Predefined batches
                    BatchOptionButton(
                        title: "All Applications",
                        description: "Process all installed applications",
                        icon: "app.fill"
                    ) {
                        onSelect(batchProcessor.createAllAppsBatch())
                    }

                    BatchOptionButton(
                        title: "System Applications",
                        description: "Process only system apps",
                        icon: "cpu"
                    ) {
                        onSelect(batchProcessor.createSystemAppsBatch())
                    }

                    BatchOptionButton(
                        title: "User Applications",
                        description: "Process only user-installed apps",
                        icon: "person.fill"
                    ) {
                        onSelect(batchProcessor.createUserAppsBatch())
                    }
                }
                .padding()
            }
        }
        .frame(width: 400, height: 300)
    }
}

struct BatchOptionButton: View {
    let title: String
    let description: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .frame(width: 40, height: 40)
                    .background(.blue.opacity(0.1))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))

                    Text(description)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.quaternary.opacity(0.3))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    BatchProcessingView()
}
