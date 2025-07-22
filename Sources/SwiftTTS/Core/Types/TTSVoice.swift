import Foundation

public struct TTSVoice: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let language: String
    public let gender: Gender
    public let source: VoiceSource
    public let quality: VoiceQuality
    
    public enum Gender: String, Codable, CaseIterable {
        case male, female, neutral
    }
    
    public enum VoiceSource: String, Codable {
        case ios = "ios"
        case ai = "ai"
    }
    
    public enum VoiceQuality: String, Codable {
        case standard, enhanced, premium
    }
    
    public init(id: String, name: String, language: String, gender: Gender, source: VoiceSource, quality: VoiceQuality = .standard) {
        self.id = id
        self.name = name
        self.language = language
        self.gender = gender
        self.source = source
        self.quality = quality
    }
}
