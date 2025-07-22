import Foundation

public struct TTSSentence: Identifiable {
    public let id = UUID()
    public let text: String
    public let voice: TTSVoice?
    public let customConfig: TTSConfiguration?
    
    public init(text: String, voice: TTSVoice? = nil, customConfig: TTSConfiguration? = nil) {
        self.text = text
        self.voice = voice
        self.customConfig = customConfig
    }
}
