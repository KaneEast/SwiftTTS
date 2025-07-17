import Foundation
import AVFoundation
import Combine

// MARK: - TTS Engine Protocol
public protocol TTSEngine {
    func speak(text: String, voice: TTSVoice, completion: @escaping (Result<Void, Error>) -> Void)
    func pause()
    func resume()
    func stop()
    var isPlaying: Bool { get }
    var isPaused: Bool { get }
}

// MARK: - Voice Models
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

// MARK: - TTS Configuration
public struct TTSConfiguration {
    public var rate: Float = 0.5          // 播放速度 (0.0 - 1.0)
    public var pitch: Float = 1.0         // 音调 (0.5 - 2.0)
    public var volume: Float = 1.0        // 音量 (0.0 - 1.0)
    public var pauseBetweenSentences: TimeInterval = 0.5  // 句子间间隔
    public var autoLanguageDetection: Bool = true
    public var preferredVoice: TTSVoice?
    
    public init() {}
}

// MARK: - TTS Events
public enum TTSEvent {
    case started(sentence: String)
    case paused
    case resumed
    case stopped
    case completed(sentence: String)
    case error(Error)
    case queueCompleted
    case progressChanged(progress: Float)
}

// MARK: - Sentence Model
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

// MARK: - Main TTS Manager
@MainActor
public class TTSManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var isPlaying = false
    @Published public var isPaused = false
    @Published public var currentSentence: TTSSentence?
    @Published public var currentProgress: Float = 0.0
    @Published public var queue: [TTSSentence] = []
    @Published public var configuration = TTSConfiguration()
    @Published public var availableVoices: [TTSVoice] = []
    
    // MARK: - Private Properties
    private var engines: [TTSEngine] = []
    private var currentEngine: TTSEngine?
    private let eventSubject = PassthroughSubject<TTSEvent, Never>()
    private var currentIndex = 0
    private let voiceManager = VoiceManager()
    private let configManager = ConfigurationManager()
    
    // MARK: - Public API
    public var eventPublisher: AnyPublisher<TTSEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    
    public init() {
        setupEngines()
        loadConfiguration()
        loadAvailableVoices()
    }
    
    // MARK: - Setup
    private func setupEngines() {
        let iosEngine = iOSTTSEngine()
        iosEngine.delegate = self
        engines.append(iosEngine)
        currentEngine = iosEngine
    }
    
    private func loadConfiguration() {
        configuration = configManager.loadConfiguration()
    }
    
    private func loadAvailableVoices() {
        availableVoices = voiceManager.getAllVoices()
    }
    
    // MARK: - Voice Management
    public func setPreferredVoice(_ voice: TTSVoice) {
        configuration.preferredVoice = voice
        configManager.saveConfiguration(configuration)
    }
    
    public func getVoicesForLanguage(_ language: String) -> [TTSVoice] {
        return voiceManager.getVoicesForLanguage(language)
    }
    
    public func detectLanguage(for text: String) -> String? {
        return voiceManager.detectLanguage(for: text)
    }
    
    // MARK: - Single Sentence Playback
    public func speak(_ text: String, voice: TTSVoice? = nil) {
        let sentence = TTSSentence(text: text, voice: voice)
        speakSentence(sentence)
    }
    
    public func speakSentence(_ sentence: TTSSentence) {
        stop() // 停止当前播放
        
        currentSentence = sentence
        let voice = selectVoice(for: sentence)
        
        isPlaying = true
        isPaused = false
        eventSubject.send(.started(sentence: sentence.text))
        
        currentEngine?.speak(text: sentence.text, voice: voice) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.handleSentenceCompleted(sentence)
                case .failure(let error):
                    self?.handleError(error)
                }
            }
        }
    }
    
    // MARK: - Queue Playback
    public func addToQueue(_ sentences: [TTSSentence]) {
        queue.append(contentsOf: sentences)
    }
    
    public func addToQueue(_ texts: [String]) {
        let sentences = texts.map { TTSSentence(text: $0) }
        addToQueue(sentences)
    }
    
    public func playQueue() {
        guard !queue.isEmpty else { return }
        
        currentIndex = 0
        playCurrentSentence()
    }
    
    public func clearQueue() {
        queue.removeAll()
        currentIndex = 0
    }
    
    private func playCurrentSentence() {
        guard currentIndex < queue.count else {
            handleQueueCompleted()
            return
        }
        
        let sentence = queue[currentIndex]
        currentSentence = sentence
        let voice = selectVoice(for: sentence)
        
        isPlaying = true
        isPaused = false
        eventSubject.send(.started(sentence: sentence.text))
        
        currentEngine?.speak(text: sentence.text, voice: voice) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.handleSentenceCompleted(sentence)
                    self?.playNextSentence()
                case .failure(let error):
                    self?.handleError(error)
                }
            }
        }
    }
    
    private func playNextSentence() {
        currentIndex += 1
        
        if currentIndex < queue.count {
            // 添加句子间间隔
            DispatchQueue.main.asyncAfter(deadline: .now() + configuration.pauseBetweenSentences) {
                self.playCurrentSentence()
            }
        } else {
            handleQueueCompleted()
        }
    }
    
    // MARK: - Playback Controls
    public func pause() {
        guard isPlaying && !isPaused else { return }
        
        currentEngine?.pause()
        isPaused = true
        eventSubject.send(.paused)
    }
    
    public func resume() {
        guard isPaused else { return }
        
        currentEngine?.resume()
        isPaused = false
        eventSubject.send(.resumed)
    }
    
    public func stop() {
        currentEngine?.stop()
        isPlaying = false
        isPaused = false
        currentSentence = nil
        currentProgress = 0.0
        eventSubject.send(.stopped)
    }
    
    public func skipToNext() {
        guard !queue.isEmpty && currentIndex < queue.count - 1 else { return }
        
        stop()
        currentIndex += 1
        playCurrentSentence()
    }
    
    public func skipToPrevious() {
        guard !queue.isEmpty && currentIndex > 0 else { return }
        
        stop()
        currentIndex -= 1
        playCurrentSentence()
    }
    
    // MARK: - Configuration
    public func updateConfiguration(_ config: TTSConfiguration) {
        self.configuration = config
        configManager.saveConfiguration(config)
    }
    
    // MARK: - AI Engine Management
    public func registerAIEngine(_ engine: TTSEngine) {
        engines.append(engine)
    }
    
    public func switchToEngine(ofType type: TTSEngine.Type) {
        currentEngine = engines.first { engine in
            Swift.type(of: engine) == type
        }
    }
    
    // MARK: - Private Helpers
    private func selectVoice(for sentence: TTSSentence) -> TTSVoice {
        // 优先级: 句子指定的voice > 配置的偏好voice > 自动检测
        if let voice = sentence.voice {
            return voice
        }
        
        if let preferredVoice = configuration.preferredVoice {
            return preferredVoice
        }
        
        // 自动语言检测
        if configuration.autoLanguageDetection,
           let detectedLanguage = detectLanguage(for: sentence.text) {
            let voicesForLanguage = getVoicesForLanguage(detectedLanguage)
            if let firstVoice = voicesForLanguage.first {
                return firstVoice
            }
        }
        
        // 默认返回第一个可用的voice
        return availableVoices.first ?? TTSVoice(id: "default", name: "Default", language: "en-US", gender: .neutral, source: .ios)
    }
    
    private func handleSentenceCompleted(_ sentence: TTSSentence) {
        eventSubject.send(.completed(sentence: sentence.text))
        currentProgress = 1.0
    }
    
    private func handleQueueCompleted() {
        isPlaying = false
        isPaused = false
        currentSentence = nil
        currentProgress = 0.0
        eventSubject.send(.queueCompleted)
    }
    
    private func handleError(_ error: Error) {
        isPlaying = false
        isPaused = false
        eventSubject.send(.error(error))
    }
}

// MARK: - TTS Engine Delegate
extension TTSManager: TTSEngineDelegate {
    func didUpdateProgress(_ progress: Float) {
        currentProgress = progress
        eventSubject.send(.progressChanged(progress: progress))
    }
}

protocol TTSEngineDelegate: AnyObject {
    func didUpdateProgress(_ progress: Float)
}
