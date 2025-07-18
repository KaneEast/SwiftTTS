import Foundation
import AVFoundation
import Combine
import UIKit

// MARK: - TTS Cache Manager
public class TTSCacheManager {
    
    public static let shared = TTSCacheManager()
    
    private let cache = NSCache<NSString, CachedAudioData>()
    private let cacheQueue = DispatchQueue(label: "com.swifttts.cache", qos: .utility)
    private var cacheSize: Int64 = 0
    private let maxCacheSize: Int64 = 100 * 1024 * 1024 // 100MB
    
    private init() {
        setupCache()
    }
    
    private func setupCache() {
        cache.countLimit = 200 // 最多缓存200个音频片段
        cache.totalCostLimit = Int(maxCacheSize)
        
        // 监听内存警告
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearCache()
        }
    }
    
    // MARK: - Cache Operations
    public func cacheAudio(_ data: Data, for key: String) {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            let cachedData = CachedAudioData(data: data, timestamp: Date())
            let cost = data.count
            
            self.cache.setObject(cachedData, forKey: NSString(string: key), cost: cost)
            self.cacheSize += Int64(cost)
            
            // 如果缓存超出限制，清理旧数据
            if self.cacheSize > self.maxCacheSize {
                self.cleanupOldCache()
            }
            
            TTSDebug("Cached audio for key: \(key), size: \(cost) bytes")
        }
    }
    
    public func getCachedAudio(for key: String) -> Data? {
        return cache.object(forKey: NSString(string: key))?.data
    }
    
    public func generateCacheKey(text: String, voice: TTSVoice, config: TTSConfiguration) -> String {
        let configHash = "\(config.rate)-\(config.pitch)-\(config.volume)"
        let combined = "\(text)-\(voice.id)-\(configHash)"
        return combined.sha256
    }
    
    private func cleanupOldCache() {
        // 这里简化实现，在实际项目中可能需要更复杂的LRU策略
        cache.removeAllObjects()
        cacheSize = 0
        TTSDebug("Cache cleaned up due to size limit")
    }
    
    public func clearCache() {
        cacheQueue.async { [weak self] in
            self?.cache.removeAllObjects()
            self?.cacheSize = 0
            TTSInfo("TTS cache cleared")
        }
    }
}

// MARK: - Cached Audio Data
private class CachedAudioData {
    let data: Data
    let timestamp: Date
    
    init(data: Data, timestamp: Date) {
        self.data = data
        self.timestamp = timestamp
    }
}

// MARK: - Performance Optimized TTS Engine
public class OptimizedTTSEngine: iOSTTSEngine {
    
    private let performanceMonitor = TTSPerformanceMonitor.shared
    private let cacheManager = TTSCacheManager.shared
    
    override public func speak(text: String, voice: TTSVoice, completion: @escaping (Result<Void, Error>) -> Void) {
        performanceMonitor.startMeasuring("TTS_Speak")
        
        // 预处理文本以提高性能
        let optimizedText = TTSUtilities.preprocessText(text)
        
        super.speak(text: optimizedText, voice: voice) { [weak self] result in
            self?.performanceMonitor.endMeasuring("TTS_Speak")
            completion(result)
        }
    }
}

// MARK: - Background Processing
public class TTSBackgroundProcessor {
    
    public static let shared = TTSBackgroundProcessor()
    
    private let processingQueue = DispatchQueue(label: "com.swifttts.background", qos: .utility)
    private let preloadQueue = DispatchQueue(label: "com.swifttts.preload", qos: .background)
    
    private init() {}
    
    // MARK: - Text Preprocessing
    public func preprocessTextsInBackground(
        _ texts: [String],
        completion: @escaping ([String]) -> Void
    ) {
        processingQueue.async {
            let processedTexts = texts.map { TTSUtilities.preprocessText($0) }
            
            DispatchQueue.main.async {
                completion(processedTexts)
            }
        }
    }
    
    // MARK: - Voice Preloading
    public func preloadVoices(for languages: [String]) {
        preloadQueue.async {
            let voiceManager = VoiceManager()
            
            for language in languages {
                let voices = voiceManager.getVoicesForLanguage(language)
                TTSDebug("Preloaded \(voices.count) voices for language: \(language)")
            }
        }
    }
    
    // MARK: - Sentence Preparation
    public func prepareSentencesInBackground(
        from text: String,
        completion: @escaping ([TTSSentence]) -> Void
    ) {
        processingQueue.async {
            let sentences = text.splitIntoSentences()
            let ttsSettings = sentences.map { TTSSentence(text: $0) }
            
            DispatchQueue.main.async {
                completion(ttsSettings)
            }
        }
    }
}

// MARK: - Memory Management
public class TTSMemoryManager {
    
    public static let shared = TTSMemoryManager()
    
    private var memoryPressureSource: DispatchSourceMemoryPressure?
    public var currentMemoryUsage: Int64 = 0
    
    private init() {
        setupMemoryMonitoring()
    }
    
    private func setupMemoryMonitoring() {
        memoryPressureSource = DispatchSource.makeMemoryPressureSource(
            eventMask: [.warning, .critical],
            queue: .main
        )
        
        memoryPressureSource?.setEventHandler { [weak self] in
            self?.handleMemoryPressure()
        }
        
        memoryPressureSource?.resume()
    }
    
    private func handleMemoryPressure() {
        TTSWarning("Memory pressure detected, cleaning up TTS resources")
        
        // 清理缓存
        TTSCacheManager.shared.clearCache()
        
        // 通知管理器释放资源
        NotificationCenter.default.post(
            name: .ttsMemoryPressureDetected,
            object: nil
        )
    }
    
    public func reportMemoryUsage(_ usage: Int64) {
        currentMemoryUsage = usage
        
        if usage > 50 * 1024 * 1024 { // 50MB
            TTSWarning("High memory usage detected: \(usage / 1024 / 1024)MB")
        }
    }
}

// MARK: - Performance Metrics
public struct TTSPerformanceMetrics {
    public let totalPlaybackTime: TimeInterval
    public let averageResponseTime: TimeInterval
    public let cacheHitRate: Double
    public let memoryUsage: Int64
    public let errorCount: Int
    
    public init(
        totalPlaybackTime: TimeInterval = 0,
        averageResponseTime: TimeInterval = 0,
        cacheHitRate: Double = 0,
        memoryUsage: Int64 = 0,
        errorCount: Int = 0
    ) {
        self.totalPlaybackTime = totalPlaybackTime
        self.averageResponseTime = averageResponseTime
        self.cacheHitRate = cacheHitRate
        self.memoryUsage = memoryUsage
        self.errorCount = errorCount
    }
}

// MARK: - Performance Analytics
public class TTSPerformanceAnalytics {
    
    public static let shared = TTSPerformanceAnalytics()
    
    private var metrics = TTSPerformanceMetrics()
    private var responseTimes: [TimeInterval] = []
    private var totalCacheRequests = 0
    private var cacheHits = 0
    private var errors = 0
    
    private init() {}
    
    public func recordResponseTime(_ time: TimeInterval) {
        responseTimes.append(time)
        
        // 保持最近100个记录
        if responseTimes.count > 100 {
            responseTimes.removeFirst()
        }
    }
    
    public func recordCacheRequest(hit: Bool) {
        totalCacheRequests += 1
        if hit {
            cacheHits += 1
        }
    }
    
    public func recordError() {
        errors += 1
    }
    
    public func getCurrentMetrics() -> TTSPerformanceMetrics {
        let avgResponseTime = responseTimes.isEmpty ? 0 : responseTimes.reduce(0, +) / Double(responseTimes.count)
        let cacheHitRate = totalCacheRequests == 0 ? 0 : Double(cacheHits) / Double(totalCacheRequests)
        
        return TTSPerformanceMetrics(
            totalPlaybackTime: metrics.totalPlaybackTime,
            averageResponseTime: avgResponseTime,
            cacheHitRate: cacheHitRate,
            memoryUsage: TTSMemoryManager.shared.currentMemoryUsage,
            errorCount: errors
        )
    }
    
    public func logPerformanceReport() {
        let currentMetrics = getCurrentMetrics()
        
        TTSInfo("""
        TTS Performance Report:
        - Average Response Time: \(String(format: "%.3f", currentMetrics.averageResponseTime))s
        - Cache Hit Rate: \(String(format: "%.1f", currentMetrics.cacheHitRate * 100))%
        - Memory Usage: \(currentMetrics.memoryUsage / 1024 / 1024)MB
        - Error Count: \(currentMetrics.errorCount)
        """)
    }
}

// MARK: - Batch Processing
public class TTSBatchProcessor {
    
    public static let shared = TTSBatchProcessor()
    
    private let batchQueue = DispatchQueue(label: "com.swifttts.batch", qos: .utility)
    private let maxBatchSize = 50
    
    private init() {}
    
    public func processBatch(
        _ sentences: [TTSSentence],
        using manager: TTSManager,
        batchSize: Int? = nil,
        progress: @escaping (Float) -> Void,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let effectiveBatchSize = batchSize ?? maxBatchSize
        let batches = sentences.chunked(into: effectiveBatchSize)
        
        batchQueue.async {
            var processedBatches = 0
            let totalBatches = batches.count
            
            for batch in batches {
                DispatchQueue.main.sync {
                    manager.addToQueue(batch)
                }
                
                processedBatches += 1
                let progressValue = Float(processedBatches) / Float(totalBatches)
                
                DispatchQueue.main.async {
                    progress(progressValue)
                }
            }
            
            DispatchQueue.main.async {
                completion(.success(()))
            }
        }
    }
}

// MARK: - Notification Extensions
public extension Notification.Name {
    static let ttsMemoryPressureDetected = Notification.Name("TTSMemoryPressureDetected")
}

// MARK: - String Hashing Extension
private extension String {
    var sha256: String {
        // TODO: K
        return ""
//        let data = self.data(using: .utf8)!
//        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
//        
//        data.withUnsafeBytes {
//            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
//        }
//        
//        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// 简化的SHA256实现（避免依赖CommonCrypto）
private func simpleSHA256(_ string: String) -> String {
    return String(string.hashValue)
}

// MARK: - Array Chunking Extension
private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Performance-Optimized TTSManager Extension
public extension TTSManager {
    
    func enablePerformanceOptimizations() {
        // 启用背景预处理
        TTSBackgroundProcessor.shared.preloadVoices(for: ["en-US", "zh-CN", "ja-JP"])
        
        // 配置内存管理
        TTSMemoryManager.shared.reportMemoryUsage(0)
        
        // 监听内存压力事件
        NotificationCenter.default.addObserver(
            forName: .ttsMemoryPressureDetected,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryPressure()
        }
        
        TTSInfo("Performance optimizations enabled")
    }
    
    private func handleMemoryPressure() {
        // 清空队列中不重要的项目
        if queue.count > 10 {
            let importantSentences = Array(queue.prefix(5))
            clearQueue()
            addToQueue(importantSentences)
        }
        
        TTSInfo("Handled memory pressure by reducing queue size")
    }
}

// MARK: - Development Tools
#if DEBUG
public class TTSPerformanceTester {
    
    public static func testTextProcessingPerformance() {
        let longText = String(repeating: "This is a test sentence. ", count: 1000)
        let startTime = CFAbsoluteTimeGetCurrent()
        
        _ = TTSUtilities.preprocessText(longText)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        print("Text processing took: \(duration) seconds")
    }
    
    public static func testCachePerformance() {
        let cache = TTSCacheManager.shared
        let testData = Data(repeating: 0, count: 1024)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<1000 {
            cache.cacheAudio(testData, for: "test_\(i)")
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        print("Cache operations took: \(duration) seconds")
    }
}
#endif
