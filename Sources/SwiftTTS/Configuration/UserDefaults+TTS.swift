import Foundation
import Observation

// MARK: - TTS Settings using Observation Framework
@Observable
public class TTSSettings {
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let languageVoiceMappingKey = "com.swifttts.languageVoiceMapping"
    private let defaultVoiceKey = "com.swifttts.defaultVoice"
    private let autoLanguageDetectionKey = "com.swifttts.autoLanguageDetection"
    private let speechRateKey = "com.swifttts.speechRate"
    private let speechPitchKey = "com.swifttts.speechPitch"
    private let speechVolumeKey = "com.swifttts.speechVolume"
    private let pauseBetweenSentencesKey = "com.swifttts.pauseBetweenSentences"
    
    // MARK: - Observable Properties
    
    /// Dictionary mapping language identifiers to voice identifiers
    public var languageVoiceMapping: [String: String] {
        get {
            return userDefaults.object(forKey: languageVoiceMappingKey) as? [String: String] ?? [:]
        }
        set {
            userDefaults.set(newValue, forKey: languageVoiceMappingKey)
        }
    }
    
    /// Default voice identifier when no specific language mapping exists
    public var defaultVoiceIdentifier: String? {
        get {
            return userDefaults.string(forKey: defaultVoiceKey)
        }
        set {
            userDefaults.set(newValue, forKey: defaultVoiceKey)
        }
    }
    
    /// Whether to automatically detect language for text
    public var autoLanguageDetection: Bool {
        get {
            return userDefaults.object(forKey: autoLanguageDetectionKey) as? Bool ?? true
        }
        set {
            userDefaults.set(newValue, forKey: autoLanguageDetectionKey)
        }
    }
    
    /// Speech rate (0.0 to 1.0)
    public var speechRate: Float {
        get {
            let rate = userDefaults.float(forKey: speechRateKey)
            return rate == 0.0 ? 0.5 : rate // Default to 0.5 if not set
        }
        set {
            let clampedValue = max(0.0, min(1.0, newValue))
            userDefaults.set(clampedValue, forKey: speechRateKey)
        }
    }
    
    /// Speech pitch multiplier (0.5 to 2.0)
    public var speechPitch: Float {
        get {
            let pitch = userDefaults.float(forKey: speechPitchKey)
            return pitch == 0.0 ? 1.0 : pitch // Default to 1.0 if not set
        }
        set {
            let clampedValue = max(0.5, min(2.0, newValue))
            userDefaults.set(clampedValue, forKey: speechPitchKey)
        }
    }
    
    /// Speech volume (0.0 to 1.0)
    public var speechVolume: Float {
        get {
            let volume = userDefaults.float(forKey: speechVolumeKey)
            return volume == 0.0 ? 1.0 : volume // Default to 1.0 if not set
        }
        set {
            let clampedValue = max(0.0, min(1.0, newValue))
            userDefaults.set(clampedValue, forKey: speechVolumeKey)
        }
    }
    
    /// Pause duration between sentences in seconds
    public var pauseBetweenSentences: TimeInterval {
        get {
            let pause = userDefaults.double(forKey: pauseBetweenSentencesKey)
            return pause == 0.0 ? 0.5 : pause // Default to 0.5 seconds if not set
        }
        set {
            let clampedValue = max(0.0, min(5.0, newValue))
            userDefaults.set(clampedValue, forKey: pauseBetweenSentencesKey)
        }
    }
    
    // MARK: - Singleton
    public static let shared = TTSSettings()
    
    private init() {
        // Private initializer for singleton pattern
    }
    
    // MARK: - Language-Voice Mapping Methods
    
    /// Set preferred voice for a specific language
    public func setVoice(_ voiceIdentifier: String, for language: Language) {
        var mapping = languageVoiceMapping
        mapping[language.code.bcp47] = voiceIdentifier
        languageVoiceMapping = mapping
    }
    
    /// Set preferred voice for a specific language code
    public func setVoice(_ voiceIdentifier: String, for languageCode: String) {
        var mapping = languageVoiceMapping
        mapping[languageCode] = voiceIdentifier
        languageVoiceMapping = mapping
    }
    
    /// Get preferred voice identifier for a specific language
    public func getVoiceIdentifier(for language: Language) -> String? {
        return languageVoiceMapping[language.code.bcp47]
    }
    
    /// Get preferred voice identifier for a specific language code
    public func getVoiceIdentifier(for languageCode: String) -> String? {
        return languageVoiceMapping[languageCode]
    }
    
    /// Remove voice mapping for a specific language
    public func removeVoiceMapping(for language: Language) {
        var mapping = languageVoiceMapping
        mapping.removeValue(forKey: language.code.bcp47)
        languageVoiceMapping = mapping
    }
    
    /// Remove voice mapping for a specific language code
    public func removeVoiceMapping(for languageCode: String) {
        var mapping = languageVoiceMapping
        mapping.removeValue(forKey: languageCode)
        languageVoiceMapping = mapping
    }
    
    /// Get all configured language codes
    public var configuredLanguages: [String] {
        return Array(languageVoiceMapping.keys).sorted()
    }
    
    /// Check if a language has a configured voice
    public func hasVoiceMapping(for language: Language) -> Bool {
        return languageVoiceMapping[language.code.bcp47] != nil
    }
    
    /// Check if a language code has a configured voice
    public func hasVoiceMapping(for languageCode: String) -> Bool {
        return languageVoiceMapping[languageCode] != nil
    }
    
    // MARK: - Bulk Operations
    
    /// Set multiple language-voice mappings at once
    public func setVoiceMappings(_ mappings: [String: String]) {
        var currentMapping = languageVoiceMapping
        for (languageCode, voiceIdentifier) in mappings {
            currentMapping[languageCode] = voiceIdentifier
        }
        languageVoiceMapping = currentMapping
    }
    
    /// Clear all language-voice mappings
    public func clearAllVoiceMappings() {
        languageVoiceMapping = [:]
    }
    
    // MARK: - Reset Methods
    
    /// Reset all settings to defaults
    public func resetToDefaults() {
        languageVoiceMapping = [:]
        defaultVoiceIdentifier = nil
        autoLanguageDetection = true
        speechRate = 0.5
        speechPitch = 1.0
        speechVolume = 1.0
        pauseBetweenSentences = 0.5
    }
    
    /// Reset only voice mappings
    public func resetVoiceMappings() {
        languageVoiceMapping = [:]
        defaultVoiceIdentifier = nil
    }
    
    /// Reset only speech parameters
    public func resetSpeechParameters() {
        speechRate = 0.5
        speechPitch = 1.0
        speechVolume = 1.0
        pauseBetweenSentences = 0.5
    }
}

// MARK: - UserDefaults Extension for TTS Keys
extension UserDefaults {
    
    /// TTS-specific UserDefaults keys
    enum TTSKeys {
        static let languageVoiceMapping = "com.swifttts.languageVoiceMapping"
        static let defaultVoice = "com.swifttts.defaultVoice"
        static let autoLanguageDetection = "com.swifttts.autoLanguageDetection"
        static let speechRate = "com.swifttts.speechRate"
        static let speechPitch = "com.swifttts.speechPitch"
        static let speechVolume = "com.swifttts.speechVolume"
        static let pauseBetweenSentences = "com.swifttts.pauseBetweenSentences"
    }
    
    /// Convenience methods for TTS settings
    var ttsLanguageVoiceMapping: [String: String] {
        get {
            return object(forKey: TTSKeys.languageVoiceMapping) as? [String: String] ?? [:]
        }
        set {
            set(newValue, forKey: TTSKeys.languageVoiceMapping)
        }
    }
    
    var ttsDefaultVoice: String? {
        get {
            return string(forKey: TTSKeys.defaultVoice)
        }
        set {
            set(newValue, forKey: TTSKeys.defaultVoice)
        }
    }
    
    var ttsAutoLanguageDetection: Bool {
        get {
            return object(forKey: TTSKeys.autoLanguageDetection) as? Bool ?? true
        }
        set {
            set(newValue, forKey: TTSKeys.autoLanguageDetection)
        }
    }
    
    var ttsSpeechRate: Float {
        get {
            let rate = float(forKey: TTSKeys.speechRate)
            return rate == 0.0 ? 0.5 : rate
        }
        set {
            set(max(0.0, min(1.0, newValue)), forKey: TTSKeys.speechRate)
        }
    }
    
    var ttsSpeechPitch: Float {
        get {
            let pitch = float(forKey: TTSKeys.speechPitch)
            return pitch == 0.0 ? 1.0 : pitch
        }
        set {
            set(max(0.5, min(2.0, newValue)), forKey: TTSKeys.speechPitch)
        }
    }
    
    var ttsSpeechVolume: Float {
        get {
            let volume = float(forKey: TTSKeys.speechVolume)
            return volume == 0.0 ? 1.0 : volume
        }
        set {
            set(max(0.0, min(1.0, newValue)), forKey: TTSKeys.speechVolume)
        }
    }
    
    var ttsPauseBetweenSentences: TimeInterval {
        get {
            let pause = double(forKey: TTSKeys.pauseBetweenSentences)
            return pause == 0.0 ? 0.5 : pause
        }
        set {
            set(max(0.0, min(5.0, newValue)), forKey: TTSKeys.pauseBetweenSentences)
        }
    }
}

// MARK: - Migration Helper
extension TTSSettings {
    
    /// Migrate settings from old ConfigurationManager format if needed
    public func migrateFromLegacySettings() {
        // This method can be called during app startup to migrate from old settings format
        // Implementation would depend on the old format structure
        
        // Example migration logic:
        /*
        if let legacyMapping = userDefaults.object(forKey: "old_language_voice_mapping") as? [String: String] {
            languageVoiceMapping = legacyMapping
            userDefaults.removeObject(forKey: "old_language_voice_mapping")
        }
        */
    }
}
