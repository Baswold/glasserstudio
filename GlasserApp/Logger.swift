import Foundation
import SwiftUI

/// Log severity levels
enum LogLevel: String, Codable, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"

    var icon: String {
        switch self {
        case .debug: return "ant.circle"
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.octagon"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }

    var color: Color {
        switch self {
        case .debug: return .gray
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .critical: return .purple
        }
    }
}

/// Individual log entry
struct LogEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let level: LogLevel
    let category: String
    let message: String
    let file: String
    let function: String
    let line: Int
    var metadata: [String: String]?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        level: LogLevel,
        category: String,
        message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.category = category
        self.message = message
        self.file = (file as NSString).lastPathComponent
        self.function = function
        self.line = line
        self.metadata = metadata
    }

    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }

    var formattedMessage: String {
        return "[\(formattedTimestamp)] [\(level.rawValue)] [\(category)] \(message)"
    }

    var detailedMessage: String {
        var parts = [formattedMessage]
        parts.append("   Location: \(file):\(line) \(function)")
        if let metadata = metadata, !metadata.isEmpty {
            parts.append("   Metadata: \(metadata)")
        }
        return parts.joined(separator: "\n")
    }
}

/// Comprehensive logging system
@MainActor
class Logger: ObservableObject {
    static let shared = Logger()

    @Published private(set) var entries: [LogEntry] = []
    @Published var minimumLevel: LogLevel = .info

    private let logDirectory: URL
    private let currentLogFile: URL
    private let maxLogFileSize: Int = 10 * 1024 * 1024 // 10 MB
    private let maxLogFiles: Int = 5

    private var fileHandle: FileHandle?

    private init() {
        // Set up log directory
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        logDirectory = appSupport.appendingPathComponent("Glasser/Logs")

        // Create log directory if needed
        try? FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true)

        // Set current log file
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        currentLogFile = logDirectory.appendingPathComponent("glasser-\(dateString).log")

        // Open file handle
        openLogFile()

        // Load recent logs
        loadRecentLogs()

        // Log startup
        info("Logger initialized", category: "System")
    }

    deinit {
        fileHandle?.closeFile()
    }

    // MARK: - Logging Methods

    func debug(
        _ message: String,
        category: String = "General",
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        metadata: [String: String]? = nil
    ) {
        log(level: .debug, message: message, category: category, file: file, function: function, line: line, metadata: metadata)
    }

    func info(
        _ message: String,
        category: String = "General",
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        metadata: [String: String]? = nil
    ) {
        log(level: .info, message: message, category: category, file: file, function: function, line: line, metadata: metadata)
    }

    func warning(
        _ message: String,
        category: String = "General",
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        metadata: [String: String]? = nil
    ) {
        log(level: .warning, message: message, category: category, file: file, function: function, line: line, metadata: metadata)
    }

    func error(
        _ message: String,
        category: String = "General",
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        metadata: [String: String]? = nil
    ) {
        log(level: .error, message: message, category: category, file: file, function: function, line: line, metadata: metadata)
    }

    func critical(
        _ message: String,
        category: String = "General",
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        metadata: [String: String]? = nil
    ) {
        log(level: .critical, message: message, category: category, file: file, function: function, line: line, metadata: metadata)
    }

    private func log(
        level: LogLevel,
        message: String,
        category: String,
        file: String,
        function: String,
        line: Int,
        metadata: [String: String]?
    ) {
        let entry = LogEntry(
            level: level,
            category: category,
            message: message,
            file: file,
            function: function,
            line: line,
            metadata: metadata
        )

        // Add to in-memory log
        entries.append(entry)

        // Trim if too many entries
        if entries.count > 1000 {
            entries.removeFirst(entries.count - 1000)
        }

        // Write to file
        writeToFile(entry)

        // Print to console if appropriate level
        if shouldLog(level: level) {
            print(entry.formattedMessage)
        }

        // Check if we need to rotate logs
        checkLogRotation()
    }

    // MARK: - File Management

    private func openLogFile() {
        if !FileManager.default.fileExists(atPath: currentLogFile.path) {
            FileManager.default.createFile(atPath: currentLogFile.path, contents: nil)
        }

        fileHandle = try? FileHandle(forWritingTo: currentLogFile)
        fileHandle?.seekToEndOfFile()
    }

    private func writeToFile(_ entry: LogEntry) {
        guard let handle = fileHandle else { return }

        let logLine = entry.detailedMessage + "\n\n"
        if let data = logLine.data(using: .utf8) {
            handle.write(data)
        }
    }

    private func checkLogRotation() {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: currentLogFile.path),
              let fileSize = attributes[.size] as? Int else {
            return
        }

        if fileSize > maxLogFileSize {
            rotateLogFiles()
        }
    }

    private func rotateLogFiles() {
        fileHandle?.closeFile()

        // Get all log files
        guard let logFiles = try? FileManager.default.contentsOfDirectory(at: logDirectory, includingPropertiesForKeys: [.creationDateKey])
            .filter({ $0.pathExtension == "log" })
            .sorted(by: { lhs, rhs in
                let lhsDate = (try? lhs.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                let rhsDate = (try? rhs.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return lhsDate > rhsDate
            }) else {
            return
        }

        // Delete old log files if we have too many
        if logFiles.count >= maxLogFiles {
            for oldFile in logFiles.dropFirst(maxLogFiles - 1) {
                try? FileManager.default.removeItem(at: oldFile)
            }
        }

        // Create new log file
        openLogFile()
    }

    private func loadRecentLogs() {
        guard let data = try? Data(contentsOf: currentLogFile),
              let content = String(data: data, encoding: .utf8) else {
            return
        }

        // Parse last 100 entries (simplified parsing)
        let lines = content.components(separatedBy: "\n\n")
        for line in lines.suffix(100) {
            if let entry = parseLogLine(line) {
                entries.append(entry)
            }
        }
    }

    private func parseLogLine(_ line: String) -> LogEntry? {
        // Simplified parsing - in production you'd want more robust parsing
        let components = line.components(separatedBy: "] ")
        guard components.count >= 3 else { return nil }

        let timestampStr = components[0].replacingOccurrences(of: "[", with: "")
        let levelStr = components[1].replacingOccurrences(of: "[", with: "")
        let categoryStr = components[2].replacingOccurrences(of: "[", with: "")

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timestamp = formatter.date(from: timestampStr) ?? Date()

        let level = LogLevel(rawValue: levelStr) ?? .info
        let message = components.dropFirst(3).joined(separator: "] ")

        return LogEntry(
            timestamp: timestamp,
            level: level,
            category: categoryStr,
            message: message
        )
    }

    // MARK: - Utilities

    private func shouldLog(level: LogLevel) -> Bool {
        let levels: [LogLevel] = [.debug, .info, .warning, .error, .critical]
        guard let currentIndex = levels.firstIndex(of: level),
              let minimumIndex = levels.firstIndex(of: minimumLevel) else {
            return true
        }
        return currentIndex >= minimumIndex
    }

    func clearLogs() {
        entries.removeAll()
        try? FileManager.default.removeItem(at: currentLogFile)
        openLogFile()
        info("Logs cleared", category: "System")
    }

    func exportLogs() -> URL? {
        return currentLogFile
    }

    func getLogsByCategory(_ category: String) -> [LogEntry] {
        return entries.filter { $0.category == category }
    }

    func getLogsByLevel(_ level: LogLevel) -> [LogEntry] {
        return entries.filter { $0.level == level }
    }

    var categories: [String] {
        return Array(Set(entries.map { $0.category })).sorted()
    }

    var errorCount: Int {
        return entries.filter { $0.level == .error || $0.level == .critical }.count
    }

    var warningCount: Int {
        return entries.filter { $0.level == .warning }.count
    }
}

// MARK: - Log Viewer UI

struct LogViewerView: View {
    @StateObject private var logger = Logger.shared
    @State private var selectedLevel: LogLevel?
    @State private var selectedCategory: String?
    @State private var searchText = ""

    var filteredLogs: [LogEntry] {
        var logs = logger.entries

        if let level = selectedLevel {
            logs = logs.filter { $0.level == level }
        }

        if let category = selectedCategory {
            logs = logs.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            logs = logs.filter { $0.message.localizedCaseInsensitiveContains(searchText) }
        }

        return logs.reversed() // Show newest first
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with controls
            HStack {
                Text("Application Logs")
                    .font(.system(size: 16, weight: .medium))

                Spacer()

                // Level filter
                Picker("Level", selection: $selectedLevel) {
                    Text("All Levels").tag(nil as LogLevel?)
                    ForEach(LogLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level as LogLevel?)
                    }
                }
                .frame(width: 150)

                // Category filter
                Picker("Category", selection: $selectedCategory) {
                    Text("All Categories").tag(nil as String?)
                    ForEach(logger.categories, id: \.self) { category in
                        Text(category).tag(category as String?)
                    }
                }
                .frame(width: 150)

                Button("Clear") {
                    logger.clearLogs()
                }

                Button("Export") {
                    if let url = logger.exportLogs() {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                }
            }
            .padding()

            Divider()

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search logs", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(.quaternary.opacity(0.3))
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Stats
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.octagon")
                        .foregroundColor(.red)
                    Text("\(logger.errorCount) errors")
                        .font(.system(size: 11))
                }

                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("\(logger.warningCount) warnings")
                        .font(.system(size: 11))
                }

                Spacer()

                Text("\(filteredLogs.count) entries")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            // Log list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(filteredLogs) { entry in
                        LogEntryRow(entry: entry)
                    }
                }
                .padding()
            }
        }
    }
}

struct LogEntryRow: View {
    let entry: LogEntry
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: entry.level.icon)
                    .foregroundColor(entry.level.color)
                    .font(.system(size: 10))

                Text(entry.formattedTimestamp)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)

                Text("[\(entry.category)]")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)

                Text(entry.message)
                    .font(.system(size: 11))
                    .lineLimit(isExpanded ? nil : 1)

                Spacer()

                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.file):\(entry.line) - \(entry.function)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.tertiary)

                    if let metadata = entry.metadata, !metadata.isEmpty {
                        ForEach(Array(metadata.keys), id: \.self) { key in
                            HStack {
                                Text("\(key):")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                                Text(metadata[key] ?? "")
                                    .font(.system(size: 9, design: .monospaced))
                            }
                        }
                    }
                }
                .padding(.leading, 24)
                .padding(.top, 4)
            }
        }
        .padding(8)
        .background(entry.level == .error || entry.level == .critical ? Color.red.opacity(0.05) : Color.clear)
        .cornerRadius(6)
    }
}

#Preview {
    LogViewerView()
        .frame(width: 800, height: 600)
}
