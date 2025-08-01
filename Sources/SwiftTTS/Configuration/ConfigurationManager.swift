import Foundation

// MARK: - Configuration Manager
public class ConfigurationManager {
    
    // MARK: - UserDefaults Keys
    private enum Keys {
        static let configuration = "SwiftTTS.Configuration"
        static let preferredVoices = "SwiftTTS.PreferredVoices"
        static let playbackHistory = "SwiftTTS.PlaybackHistory"
    }
    
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // MARK: - Configuration Management
    public func saveConfiguration(_ config: TTSConfiguration) {
        do {
            let data = try encoder.encode(config)
            userDefaults.set(data, forKey: Keys.configuration)
        } catch {
            print("Failed to save configuration: \(error)")
        }
    }
    
    public func loadConfiguration() -> TTSConfiguration {
        guard let data = userDefaults.data(forKey: Keys.configuration) else {
            return TTSConfiguration()
        }
        
        do {
            return try decoder.decode(TTSConfiguration.self, from: data)
        } catch {
            print("Failed to load configuration: \(error)")
            return TTSConfiguration()
        }
    }
    
    // MARK: - Preferred Voices Management
    public func savePreferredVoices(_ voices: [String: TTSVoice]) {
        do {
            let data = try encoder.encode(voices)
            userDefaults.set(data, forKey: Keys.preferredVoices)
        } catch {
            print("Failed to save preferred voices: \(error)")
        }
    }
    
    public func loadPreferredVoices() -> [String: TTSVoice] {
        guard let data = userDefaults.data(forKey: Keys.preferredVoices) else {
            return [:]
        }
        
        do {
            return try decoder.decode([String: TTSVoice].self, from: data)
        } catch {
            print("Failed to load preferred voices: \(error)")
            return [:]
        }
    }
    
    public func setPreferredVoice(_ voice: TTSVoice, for language: Language) {
        var preferredVoices = loadPreferredVoices()
        preferredVoices[language.code.bcp47] = voice
        savePreferredVoices(preferredVoices)
    }
    
    public func getPreferredVoice(for language: Language) -> TTSVoice? {
        let preferredVoices = loadPreferredVoices()
        return preferredVoices[language.code.bcp47]
    }
    
    // Legacy String-based methods for backward compatibility
    public func setPreferredVoice(_ voice: TTSVoice, for languageCode: String) {
        setPreferredVoice(voice, for: Language(code: .bcp47(languageCode)))
    }
    
    public func getPreferredVoice(for languageCode: String) -> TTSVoice? {
        return getPreferredVoice(for: Language(code: .bcp47(languageCode)))
    }
    
    // MARK: - Playback History (扩展功能)
    public func savePlaybackHistory(_ history: [PlaybackHistoryItem]) {
        do {
            let data = try encoder.encode(history)
            userDefaults.set(data, forKey: Keys.playbackHistory)
        } catch {
            print("Failed to save playback history: \(error)")
        }
    }
    
    public func loadPlaybackHistory() -> [PlaybackHistoryItem] {
        guard let data = userDefaults.data(forKey: Keys.playbackHistory) else {
            return []
        }
        
        do {
            return try decoder.decode([PlaybackHistoryItem].self, from: data)
        } catch {
            print("Failed to load playback history: \(error)")
            return []
        }
    }
    
    public func addToPlaybackHistory(_ item: PlaybackHistoryItem) {
        var history = loadPlaybackHistory()
        
        // 避免重复记录相同的文本
        history.removeAll { $0.text == item.text }
        
        // 添加到开头
        history.insert(item, at: 0)
        
        // 限制历史记录数量
        if history.count > 100 {
            history = Array(history.prefix(100))
        }
        
        savePlaybackHistory(history)
    }
    
    // MARK: - Reset Functions
    public func resetConfiguration() {
        userDefaults.removeObject(forKey: Keys.configuration)
    }
    
    public func resetPreferredVoices() {
        userDefaults.removeObject(forKey: Keys.preferredVoices)
    }
    
    public func resetPlaybackHistory() {
        userDefaults.removeObject(forKey: Keys.playbackHistory)
    }
    
    public func resetAllData() {
        resetConfiguration()
        resetPreferredVoices()
        resetPlaybackHistory()
    }
}

// MARK: - Playback History Item
public struct PlaybackHistoryItem: Codable, Identifiable {
    public let id = UUID()
    public let text: String
    public let voice: TTSVoice
    public let timestamp: Date
    public let duration: TimeInterval?
    
    public init(text: String, voice: TTSVoice, duration: TimeInterval? = nil) {
        self.text = text
        self.voice = voice
        self.timestamp = Date()
        self.duration = duration
    }
}

// MARK: - Configuration Extensions
extension TTSConfiguration: Codable {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        rate = try container.decodeIfPresent(Float.self, forKey: .rate) ?? 0.5
        pitch = try container.decodeIfPresent(Float.self, forKey: .pitch) ?? 1.0
        volume = try container.decodeIfPresent(Float.self, forKey: .volume) ?? 1.0
        pauseBetweenSentences = try container.decodeIfPresent(TimeInterval.self, forKey: .pauseBetweenSentences) ?? 0.5
        autoLanguageDetection = try container.decodeIfPresent(Bool.self, forKey: .autoLanguageDetection) ?? true
        preferredVoice = try container.decodeIfPresent(TTSVoice.self, forKey: .preferredVoice)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(rate, forKey: .rate)
        try container.encode(pitch, forKey: .pitch)
        try container.encode(volume, forKey: .volume)
        try container.encode(pauseBetweenSentences, forKey: .pauseBetweenSentences)
        try container.encode(autoLanguageDetection, forKey: .autoLanguageDetection)
        try container.encodeIfPresent(preferredVoice, forKey: .preferredVoice)
    }
    
    private enum CodingKeys: String, CodingKey {
        case rate, pitch, volume, pauseBetweenSentences, autoLanguageDetection, preferredVoice
    }
}
