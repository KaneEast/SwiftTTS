import Foundation

public struct TTSConfiguration {
    public var rate: Float = 0.5          // 播放速度 (0.0 - 1.0)
    public var pitch: Float = 1.0         // 音调 (0.5 - 2.0)
    public var volume: Float = 1.0        // 音量 (0.0 - 1.0)
    public var pauseBetweenSentences: TimeInterval = 0.5  // 句子间间隔
    public var autoLanguageDetection: Bool = true
    public var preferredVoice: TTSVoice?
    
    public init() {}
}
