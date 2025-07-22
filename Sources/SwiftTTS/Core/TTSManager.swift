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
    
    public func getVoicesForLanguage(_ language: Language) -> [TTSVoice] {
        return voiceManager.getVoicesForLanguage(language)
    }
    
    public func getVoicesForLanguage(_ languageCode: String) -> [TTSVoice] {
        return voiceManager.getVoicesForLanguage(languageCode)
    }
    
    public func detectLanguage(for text: String) -> Language? {
        return voiceManager.detectLanguage(for: text)
    }
    
    public func detectLanguageCode(for text: String) -> String? {
        return voiceManager.detectLanguageCode(for: text)
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
        return availableVoices.first ?? TTSVoice(id: "default", name: "Default", languageCode: "en-US", gender: .neutral, source: .ios)
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
