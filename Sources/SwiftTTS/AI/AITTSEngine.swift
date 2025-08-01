import Foundation
import AVFoundation

// MARK: - Base AI TTS Engine
public class AITTSEngine: NSObject, TTSEngine {
    
    // MARK: - Properties
    public let service: AITTSService
    private var audioPlayer: AVAudioPlayer?
    private var completion: ((Result<Void, Error>) -> Void)?
    private var currentConfiguration: TTSConfiguration?
    
    weak var delegate: TTSEngineDelegate?
    
    public var isPlaying: Bool {
        return audioPlayer?.isPlaying ?? false
    }
    
    public var isPaused: Bool = false
    
    // MARK: - Initialization
    public init(service: AITTSService) {
        self.service = service
        super.init()
        setupAudioSession()
    }
    
    // MARK: - TTSEngine Protocol
    public func speak(text: String, voice: TTSVoice, completion: @escaping (Result<Void, Error>) -> Void) {
        self.completion = completion
        
        // 检查voice是否被支持
        guard service.isVoiceSupported(voice) else {
            completion(.failure(AITTSError.voiceNotSupported))
            return
        }
        
        // 使用当前配置或默认配置
        let config = currentConfiguration ?? TTSConfiguration()
        
        // 调用AI服务合成语音
        service.synthesizeSpeech(text: text, voice: voice, configuration: config) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let audioData):
                    self?.playAudioData(audioData)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    public func pause() {
        guard let player = audioPlayer else { return }
        
        if player.isPlaying {
            player.pause()
            isPaused = true
        }
    }
    
    public func resume() {
        guard let player = audioPlayer, isPaused else { return }
        
        player.play()
        isPaused = false
    }
    
    public func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPaused = false
        completion = nil
    }
    
    // MARK: - Configuration
    public func updateConfiguration(_ config: TTSConfiguration) {
        currentConfiguration = config
    }
    
    // MARK: - Private Methods
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func playAudioData(_ data: Data) {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPaused = false
        } catch {
            completion?(.failure(AITTSError.audioConversionFailed))
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension AITTSEngine: AVAudioPlayerDelegate {
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            completion?(.success(()))
        } else {
            completion?(.failure(AITTSError.audioConversionFailed))
        }
        
        audioPlayer = nil
        completion = nil
        isPaused = false
    }
    
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        completion?(.failure(error ?? AITTSError.audioConversionFailed))
        audioPlayer = nil
        completion = nil
        isPaused = false
    }
}

