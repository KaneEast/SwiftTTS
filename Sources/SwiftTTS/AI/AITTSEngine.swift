import Foundation
import AVFoundation

// MARK: - AI TTS Service Protocol
public protocol AITTSService {
    var name: String { get }
    var supportedVoices: [TTSVoice] { get }
    
    func synthesizeSpeech(
        text: String,
        voice: TTSVoice,
        configuration: TTSConfiguration,
        completion: @escaping (Result<Data, Error>) -> Void
    )
    
    func isVoiceSupported(_ voice: TTSVoice) -> Bool
}

// MARK: - AI TTS Error Types
public enum AITTSError: Error, LocalizedError {
    case networkError(Error)
    case authenticationFailed
    case invalidResponse
    case voiceNotSupported
    case quotaExceeded
    case serverError(Int)
    case audioConversionFailed
    
    public var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .authenticationFailed:
            return "Authentication failed"
        case .invalidResponse:
            return "Invalid response from server"
        case .voiceNotSupported:
            return "Voice not supported"
        case .quotaExceeded:
            return "Quota exceeded"
        case .serverError(let code):
            return "Server error: \(code)"
        case .audioConversionFailed:
            return "Audio conversion failed"
        }
    }
}

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

// MARK: - Example OpenAI TTS Service Implementation
public class OpenAITTSService: AITTSService {
    
    public let name = "OpenAI TTS"
    
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/audio/speech"
    
    public var supportedVoices: [TTSVoice] {
        return [
            TTSVoice(id: "alloy", name: "Alloy", language: "en-US", gender: .neutral, source: .ai, quality: .premium),
            TTSVoice(id: "echo", name: "Echo", language: "en-US", gender: .male, source: .ai, quality: .premium),
            TTSVoice(id: "fable", name: "Fable", language: "en-US", gender: .neutral, source: .ai, quality: .premium),
            TTSVoice(id: "onyx", name: "Onyx", language: "en-US", gender: .male, source: .ai, quality: .premium),
            TTSVoice(id: "nova", name: "Nova", language: "en-US", gender: .female, source: .ai, quality: .premium),
            TTSVoice(id: "shimmer", name: "Shimmer", language: "en-US", gender: .female, source: .ai, quality: .premium)
        ]
    }
    
    public init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    public func synthesizeSpeech(
        text: String,
        voice: TTSVoice,
        configuration: TTSConfiguration,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        guard let url = URL(string: baseURL) else {
            completion(.failure(AITTSError.invalidResponse))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "tts-1",
            "input": text,
            "voice": voice.id,
            "speed": configuration.rate
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(AITTSError.invalidResponse))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(AITTSError.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(AITTSError.invalidResponse))
                return
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                completion(.failure(AITTSError.serverError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(AITTSError.invalidResponse))
                return
            }
            
            completion(.success(data))
        }.resume()
    }
    
    public func isVoiceSupported(_ voice: TTSVoice) -> Bool {
        return supportedVoices.contains { $0.id == voice.id }
    }
}

// MARK: - Example Azure TTS Service Implementation
public class AzureTTSService: AITTSService {
    
    public let name = "Azure Cognitive Services TTS"
    
    private let subscriptionKey: String
    private let region: String
    
    public var supportedVoices: [TTSVoice] {
        // Azure支持大量语音，这里只列出一些示例
        return [
            TTSVoice(id: "en-US-AriaNeural", name: "Aria", language: "en-US", gender: .female, source: .ai, quality: .premium),
            TTSVoice(id: "en-US-DavisNeural", name: "Davis", language: "en-US", gender: .male, source: .ai, quality: .premium),
            TTSVoice(id: "zh-CN-XiaoxiaoNeural", name: "Xiaoxiao", language: "zh-CN", gender: .female, source: .ai, quality: .premium),
            TTSVoice(id: "zh-CN-YunyeNeural", name: "Yunye", language: "zh-CN", gender: .male, source: .ai, quality: .premium)
        ]
    }
    
    public init(subscriptionKey: String, region: String) {
        self.subscriptionKey = subscriptionKey
        self.region = region
    }
    
    public func synthesizeSpeech(
        text: String,
        voice: TTSVoice,
        configuration: TTSConfiguration,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        let endpoint = "https://\(region).tts.speech.microsoft.com/cognitiveservices/v1"
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(AITTSError.invalidResponse))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(subscriptionKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        request.setValue("application/ssml+xml", forHTTPHeaderField: "Content-Type")
        request.setValue("audio-24khz-48kbitrate-mono-mp3", forHTTPHeaderField: "X-Microsoft-OutputFormat")
        request.setValue("SwiftTTS/1.0", forHTTPHeaderField: "User-Agent")
        
        // 构建SSML
        let ssml = buildSSML(text: text, voice: voice, configuration: configuration)
        request.httpBody = ssml.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(AITTSError.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(AITTSError.invalidResponse))
                return
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                completion(.failure(AITTSError.serverError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(AITTSError.invalidResponse))
                return
            }
            
            completion(.success(data))
        }.resume()
    }
    
    public func isVoiceSupported(_ voice: TTSVoice) -> Bool {
        return supportedVoices.contains { $0.id == voice.id }
    }
    
    private func buildSSML(text: String, voice: TTSVoice, configuration: TTSConfiguration) -> String {
        let rate = Int((configuration.rate - 0.5) * 100) // 转换为百分比
        let pitch = String(format: "%.1f", configuration.pitch)
        
        return """
        <speak version='1.0' xml:lang='en-US'>
            <voice xml:lang='\(voice.language)' name='\(voice.id)'>
                <prosody rate='\(rate)%' pitch='\(pitch)'>
                    \(text)
                </prosody>
            </voice>
        </speak>
        """
    }
}
