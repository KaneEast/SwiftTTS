import Foundation
import os.log

// MARK: - TTS Logger
public class TTSLogger {
    
    // MARK: - Singleton
    public static let shared = TTSLogger()
    
    // MARK: - Properties
    private let osLog: OSLog
    private var currentLogLevel: TTSLogLevel = .info
    private var isEnabled: Bool = true
    private let dateFormatter: DateFormatter
    private var logFileURL: URL?
    
    // MARK: - Configuration
    public struct Configuration {
        public var level: TTSLogLevel = .info
        public var isEnabled: Bool = true
        public var enableFileLogging: Bool = false
        public var logFileMaxSize: Int = 1024 * 1024 // 1MB
        public var includeSourceInfo: Bool = true
        
        public init() {}
    }
    
    // MARK: - Initialization
    private init() {
        self.osLog = OSLog(subsystem: "com.swifttts.library", category: "TTS")
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        setupLogFile()
    }
    
    // MARK: - Configuration
    public func configure(with config: Configuration) {
        currentLogLevel = config.level
        isEnabled = config.isEnabled
        
        if config.enableFileLogging {
            setupLogFile()
        }
    }
    
    // MARK: - Logging Methods
    public func verbose(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .verbose, message: message, file: file, function: function, line: line)
    }
    
    public func debug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .debug, message: message, file: file, function: function, line: line)
    }
    
    public func info(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .info, message: message, file: file, function: function, line: line)
    }
    
    public func warning(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .warning, message: message, file: file, function: function, line: line)
    }
    
    public func error(
        _ message: String,
        error: Error? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var fullMessage = message
        if let error = error {
            fullMessage += " | Error: \(error.localizedDescription)"
        }
        log(level: .error, message: fullMessage, file: file, function: function, line: line)
    }
    
    public func critical(
        _ message: String,
        error: Error? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var fullMessage = message
        if let error = error {
            fullMessage += " | Error: \(error.localizedDescription)"
        }
        log(level: .critical, message: fullMessage, file: file, function: function, line: line)
    }
    
    // MARK: - Core Logging
    private func log(
        level: TTSLogLevel,
        message: String,
        file: String,
        function: String,
        line: Int
    ) {
        guard isEnabled && level >= currentLogLevel else { return }
        
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let sourceInfo = "[\(fileName):\(line) \(function)]"
        let timestamp = dateFormatter.string(from: Date())
        
        let formattedMessage = "\(level.emoji) [\(timestamp)] \(sourceInfo) \(message)"
        
        // Console logging
        print(formattedMessage)
        
        // OS Log
        os_log("%{public}@", log: osLog, type: level.osLogType, formattedMessage)
        
        // File logging
        writeToFile(formattedMessage)
    }
    
    // MARK: - File Logging
    private func setupLogFile() {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        logFileURL = documentsDirectory.appendingPathComponent("SwiftTTS.log")
    }
    
    private func writeToFile(_ message: String) {
        guard let logFileURL = logFileURL else { return }
        
        let logEntry = message + "\n"
        
        if FileManager.default.fileExists(atPath: logFileURL.path) {
            // Append to existing file
            if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(logEntry.data(using: .utf8) ?? Data())
                fileHandle.closeFile()
            }
        } else {
            // Create new file
            try? logEntry.write(to: logFileURL, atomically: true, encoding: .utf8)
        }
        
        // Check file size and rotate if necessary
        rotateLogFileIfNeeded()
    }
    
    private func rotateLogFileIfNeeded() {
        guard let logFileURL = logFileURL else { return }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: logFileURL.path)
            if let fileSize = attributes[.size] as? Int, fileSize > 1024 * 1024 { // 1MB
                let backupURL = logFileURL.appendingPathExtension("old")
                
                // Remove old backup
                try? FileManager.default.removeItem(at: backupURL)
                
                // Move current log to backup
                try FileManager.default.moveItem(at: logFileURL, to: backupURL)
            }
        } catch {
            print("Failed to rotate log file: \(error)")
        }
    }
    
    // MARK: - Log Retrieval
    public func getLogContents() -> String? {
        guard let logFileURL = logFileURL else { return nil }
        return try? String(contentsOf: logFileURL)
    }
    
    public func clearLogs() {
        guard let logFileURL = logFileURL else { return }
        try? FileManager.default.removeItem(at: logFileURL)
    }
}

// MARK: - TTS Specific Logging Extensions
public extension TTSLogger {
    
    func logTTSEvent(_ event: TTSEvent) {
        switch event {
        case .started(let sentence):
            info("TTS Started: \(sentence.prefix(50))...")
        case .paused:
            info("TTS Paused")
        case .resumed:
            info("TTS Resumed")
        case .stopped:
            info("TTS Stopped")
        case .completed(let sentence):
            info("TTS Completed: \(sentence.prefix(50))...")
        case .error(let error):
            self.error("TTS Error occurred", error: error)
        case .queueCompleted:
            info("TTS Queue Completed")
        case .progressChanged(let progress):
            verbose("TTS Progress: \(Int(progress * 100))%")
        }
    }
    
    func logVoiceSelection(_ voice: TTSVoice) {
        info("Voice Selected: \(voice.name) (\(voice.language))")
    }
    
    func logConfigurationChange(_ config: TTSConfiguration) {
        info("Configuration Updated: rate=\(config.rate), pitch=\(config.pitch), volume=\(config.volume)")
    }
    
    func logEngineSwitch(from oldEngine: String, to newEngine: String) {
        info("TTS Engine Switch: \(oldEngine) → \(newEngine)")
    }
    
    func logAIServiceCall(service: String, text: String, voice: TTSVoice) {
        info("AI Service Call: \(service) | Voice: \(voice.name) | Text: \(text.prefix(100))...")
    }
    
    func logPerformanceMetric(operation: String, duration: TimeInterval) {
        debug("Performance: \(operation) took \(String(format: "%.3f", duration))s")
    }
}

// MARK: - Performance Measurement
public class TTSPerformanceMonitor {
    
    private var startTimes: [String: Date] = [:]
    private let logger = TTSLogger.shared
    
    public static let shared = TTSPerformanceMonitor()
    
    private init() {}
    
    public func startMeasuring(_ operation: String) {
        startTimes[operation] = Date()
        logger.verbose("Performance: Started measuring \(operation)")
    }
    
    public func endMeasuring(_ operation: String) {
        guard let startTime = startTimes[operation] else {
            logger.warning("Performance: No start time found for \(operation)")
            return
        }
        
        let duration = Date().timeIntervalSince(startTime)
        startTimes.removeValue(forKey: operation)
        
        logger.logPerformanceMetric(operation: operation, duration: duration)
        
        // Log warning for slow operations
        if duration > 1.0 {
            logger.warning("Performance: Slow operation detected - \(operation) took \(String(format: "%.3f", duration))s")
        }
    }
    
    public func measure<T>(_ operation: String, block: () throws -> T) rethrows -> T {
        startMeasuring(operation)
        defer { endMeasuring(operation) }
        return try block()
    }
}

// MARK: - Convenience Functions
public func TTSLog(_ level: TTSLogLevel, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    switch level {
    case .verbose:
        TTSLogger.shared.verbose(message, file: file, function: function, line: line)
    case .debug:
        TTSLogger.shared.debug(message, file: file, function: function, line: line)
    case .info:
        TTSLogger.shared.info(message, file: file, function: function, line: line)
    case .warning:
        TTSLogger.shared.warning(message, file: file, function: function, line: line)
    case .error:
        TTSLogger.shared.error(message, file: file, function: function, line: line)
    case .critical:
        TTSLogger.shared.critical(message, file: file, function: function, line: line)
    }
}

// Convenience functions for each log level
public func TTSVerbose(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    TTSLogger.shared.verbose(message, file: file, function: function, line: line)
}

public func TTSDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    TTSLogger.shared.debug(message, file: file, function: function, line: line)
}

public func TTSInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    TTSLogger.shared.info(message, file: file, function: function, line: line)
}

public func TTSWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    TTSLogger.shared.warning(message, file: file, function: function, line: line)
}

public func TTSError(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
    TTSLogger.shared.error(message, error: error, file: file, function: function, line: line)
}

public func TTSCritical(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
    TTSLogger.shared.critical(message, error: error, file: file, function: function, line: line)
}
