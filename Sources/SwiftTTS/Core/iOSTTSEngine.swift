import Foundation
import AVFoundation

// MARK: - iOS TTS Engine Implementation
public class iOSTTSEngine: NSObject, TTSEngine {
    
    // MARK: - Properties
    private let synthesizer = AVSpeechSynthesizer()
    private var currentUtterance: AVSpeechUtterance?
    private var completion: ((Result<Void, Error>) -> Void)?
    
    weak var delegate: TTSEngineDelegate?
    
    public var isPlaying: Bool {
        return synthesizer.isSpeaking
    }
    
    public var isPaused: Bool {
        return synthesizer.isPaused
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    // MARK: - TTSEngine Protocol
    public func speak(text: String, voice: TTSVoice, completion: @escaping (Result<Void, Error>) -> Void) {
        self.completion = completion
        
        let utterance = AVSpeechUtterance(string: text)
        
        // 配置utterance
        configureUtterance(utterance, with: voice)
        
        currentUtterance = utterance
        synthesizer.speak(utterance)
    }
    
    public func pause() {
        synthesizer.pauseSpeaking(at: .immediate)
    }
    
    public func resume() {
        synthesizer.continueSpeaking()
    }
    
    public func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        currentUtterance = nil
        completion = nil
    }
    
    // MARK: - Private Methods
    private func configureUtterance(_ utterance: AVSpeechUtterance, with voice: TTSVoice) {
        // 设置语音
        if let avVoice = findAVSpeechVoice(for: voice) {
            utterance.voice = avVoice
        }
        
        // 这里可以从全局配置中获取参数，暂时使用默认值
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
    }
    
    private func findAVSpeechVoice(for voice: TTSVoice) -> AVSpeechSynthesisVoice? {
        return AVSpeechSynthesisVoice(identifier: voice.id) ??
        AVSpeechSynthesisVoice(language: voice.language.id)
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension iOSTTSEngine: AVSpeechSynthesizerDelegate {
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        // TTS开始播放
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        // TTS暂停
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        // TTS继续播放
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        completion?(.success(()))
        completion = nil
        currentUtterance = nil
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        completion?(.success(()))
        completion = nil
        currentUtterance = nil
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        // 计算播放进度
        let totalLength = utterance.speechString.count
        let currentPosition = characterRange.location + characterRange.length
        let progress = Float(currentPosition) / Float(totalLength)
        
        delegate?.didUpdateProgress(progress)
    }
}
