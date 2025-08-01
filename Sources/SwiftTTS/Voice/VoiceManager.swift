import Foundation
import AVFoundation
import NaturalLanguage

// MARK: - Voice Manager
public class VoiceManager {
    
    // MARK: - Properties
    private var cachedVoices: [TTSVoice] = []
    private let languageRecognizer = NLLanguageRecognizer()
    
    // MARK: - Language Code Mapping
    private let languageMapping: [String: String] = [
        "zh": "zh-CN",      // 中文简体
        "zh-Hans": "zh-CN", // 中文简体
        "zh-Hant": "zh-TW", // 中文繁体
        "en": "en-US",      // 英语
        "ja": "ja-JP",      // 日语
        "ko": "ko-KR",      // 韩语
        "fr": "fr-FR",      // 法语
        "de": "de-DE",      // 德语
        "es": "es-ES",      // 西班牙语
        "it": "it-IT",      // 意大利语
        "pt": "pt-BR",      // 葡萄牙语
        "ru": "ru-RU",      // 俄语
        "ar": "ar-SA",      // 阿拉伯语
        "th": "th-TH",      // 泰语
        "vi": "vi-VN",      // 越南语
    ]
    
    // MARK: - Public Methods
    public func getAllVoices() -> [TTSVoice] {
        if cachedVoices.isEmpty {
            loadiOSVoices()
        }
        return cachedVoices
    }
    
    public func getVoicesForLanguage(_ language: Language) -> [TTSVoice] {
        return getAllVoices().filter { voice in
            voice.language.matches(language) || voice.language.matchesExactly(language)
        }
    }
    
    public func getVoicesForLanguage(_ languageCode: String) -> [TTSVoice] {
        let language = Language(code: .bcp47(languageCode))
        return getVoicesForLanguage(language)
    }
    
    public func detectLanguage(for text: String) -> Language? {
        languageRecognizer.reset()
        languageRecognizer.processString(text)
        
        guard let dominantLanguage = languageRecognizer.dominantLanguage else {
            return nil
        }
        
        let languageCode = dominantLanguage.rawValue
        return Language(code: .bcp47(normalizeLanguageCode(languageCode)))
    }
    
    public func detectLanguageCode(for text: String) -> String? {
        return detectLanguage(for: text)?.code.bcp47
    }
    
    public func findVoice(by id: String) -> TTSVoice? {
        return getAllVoices().first { $0.id == id }
    }
    
    public func getDefaultVoice(for language: Language) -> TTSVoice? {
        let voices = getVoicesForLanguage(language)
        
        return voices.first { $0.gender == .female && $0.quality == .enhanced } ??
               voices.first { $0.gender == .female } ??
               voices.first
    }
    
    public func getDefaultVoice(for languageCode: String) -> TTSVoice? {
        let language = Language(code: .bcp47(languageCode))
        return getDefaultVoice(for: language)
    }
    
    public func getVoicesGroupedByNation() -> [String: [TTSVoice]] {
        let voices = getAllVoices()
        return Dictionary(grouping: voices) { voice in
            voice.language.regionCode ?? "Unknown"
        }
    }
    
    public func getVoicesGroupedByLanguage() -> [String: [TTSVoice]] {
        let voices = getAllVoices()
        return Dictionary(grouping: voices) { voice in
            voice.language.languageCode ?? "Unknown"
        }
    }
    
    public func getAvailableLanguages() -> [Language] {
        let voices = getAllVoices()
        let uniqueLanguages = Set(voices.map { $0.language })
        return Array(uniqueLanguages).sorted { $0.code.bcp47 < $1.code.bcp47 }
    }
    
    public func getAvailableRegions() -> [String] {
        let voices = getAllVoices()
        let regions = Set(voices.compactMap { $0.language.regionCode })
        return Array(regions).sorted()
    }
    
    public func getVoicesForRegion(_ regionCode: String) -> [TTSVoice] {
        return getAllVoices().filter { voice in
            voice.language.regionCode == regionCode
        }
    }
    
    public func getVoicesForLanguageFamily(_ languageCode: String) -> [TTSVoice] {
        return getAllVoices().filter { voice in
            voice.language.languageCode == languageCode
        }
    }
    
    public func getVoicesForLanguageFamily(_ language: Language) -> [TTSVoice] {
        return getAllVoices().filter { voice in
            voice.language.languageCode == language.languageCode
        }
    }
    
    public func searchVoices(query: String) -> [TTSVoice] {
        let lowercaseQuery = query.lowercased()
        return getAllVoices().filter { voice in
            voice.name.lowercased().contains(lowercaseQuery) ||
            voice.language.code.bcp47.lowercased().contains(lowercaseQuery) ||
            voice.language.localizedDescription().lowercased().contains(lowercaseQuery)
        }
    }
    
    public func getPreferredVoices(maxCount: Int = 10) -> [TTSVoice] {
        let voices = getAllVoices()
        let preferredLanguages = [Language.current] + Language.all.prefix(5)
        
        var result: [TTSVoice] = []
        for language in preferredLanguages {
            if let voice = getDefaultVoice(for: language) {
                result.append(voice)
                if result.count >= maxCount { break }
            }
        }
        
        return result
    }
    
    // MARK: - Private Methods
    private func loadiOSVoices() {
        cachedVoices = AVSpeechSynthesisVoice.speechVoices()
            .filter { !$0.identifier.contains("eloquence") }
            .compactMap { avVoice in
            createTTSVoice(from: avVoice)
        }.sorted { $0.language < $1.language }
    }
    
    private func createTTSVoice(from avVoice: AVSpeechSynthesisVoice) -> TTSVoice? {
        let language = avVoice.language
        
        let gender = determineGender(from: avVoice)
        let quality = determineQuality(from: avVoice.quality)
        
        return TTSVoice(
            id: avVoice.identifier,
            name: avVoice.name,
            languageCode: language,
            gender: gender,
            source: .ios,
            quality: quality
        )
    }
    
    private func determineGender(from voice: AVSpeechSynthesisVoice) -> TTSVoice.Gender {
        switch voice.gender {
        case .unspecified:
            return .unspecified
        case .male:
            return .male
        case .female:
            return .female
        @unknown default:
            return .unspecified
        }
    }
    
    private func determineQuality(from quality: AVSpeechSynthesisVoiceQuality) -> TTSVoice.VoiceQuality {
        switch quality {
        case .default:
            return .standard
        case .enhanced:
            return .enhanced
        case .premium:
            return .premium
        @unknown default:
            return .standard
        }
    }
    
    private func normalizeLanguageCode(_ code: String) -> String {
        // 先尝试直接映射
        if let mapped = languageMapping[code] {
            return mapped
        }
        
        // 处理带地区的语言代码 (如 en-US, zh-CN)
        if code.contains("-") {
            let components = code.components(separatedBy: "-")
            if components.count >= 2 {
                let baseLanguage = components[0].lowercased()
                if let mapped = languageMapping[baseLanguage] {
                    return mapped
                }
                return code // 如果已经是完整格式，直接返回
            }
        }
        
        // 处理下划线分隔的格式 (如 zh_CN)
        if code.contains("_") {
            let normalizedCode = code.replacingOccurrences(of: "_", with: "-")
            return normalizeLanguageCode(normalizedCode)
        }
        
        // 如果没有找到映射，返回原始代码
        return code
    }
}
