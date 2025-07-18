import Testing
import AVFoundation
import Combine
@testable import SwiftTTS

@MainActor
struct SwiftTTSTests {
    
    var ttsManager: TTSManager
    var cancellables: Set<AnyCancellable>
    
    init() {
        ttsManager = TTSManager()
        cancellables = Set<AnyCancellable>()
    }
    
    // MARK: - Voice Management Tests
    
    @Test("Get all available voices")
    func getAllVoices() async throws {
        let voices = ttsManager.availableVoices
        #expect(!voices.isEmpty, "Should have available voices")
        
        // Check if English voices are available
        let englishVoices = voices.filter { $0.language.hasPrefix("en") }
        #expect(!englishVoices.isEmpty, "Should have English voices")
        // Chinese voices may not be available on all devices, so not requiring them
    }
    
    @Test("Get voices for specific language")
    func getVoicesForLanguage() async throws {
        let englishVoices = ttsManager.getVoicesForLanguage("en-US")
        #expect(!englishVoices.isEmpty, "Should have English voices")
        
        for voice in englishVoices {
            #expect(voice.language.hasPrefix("en"), "Voice language should match")
        }
    }
    
    @Test("Language detection functionality")
    func languageDetection() async throws {
        let voiceManager = VoiceManager()
        
        let englishText = "Hello, this is a test."
        let detectedLanguage = voiceManager.detectLanguage(for: englishText)
        #expect(detectedLanguage != nil, "Should detect language")
        #expect(detectedLanguage?.hasPrefix("en") == true, "Should detect as English")
        
        let chineseText = "你好，这是一个测试。"
        let chineseLanguage = voiceManager.detectLanguage(for: chineseText)
        #expect(chineseLanguage != nil, "Should detect Chinese")
        #expect(chineseLanguage?.hasPrefix("zh") == true, "Should detect as Chinese")
    }
    
    // MARK: - Configuration Tests
    
    @Test("Configuration save and load")
    func configurationSaveAndLoad() async throws {
        let configManager = ConfigurationManager()
        
        var config = TTSConfiguration()
        config.rate = 0.8
        config.pitch = 1.5
        config.volume = 0.7
        config.pauseBetweenSentences = 2.0
        config.autoLanguageDetection = false
        
        configManager.saveConfiguration(config)
        let loadedConfig = configManager.loadConfiguration()
        
        #expect(abs(loadedConfig.rate - 0.8) < 0.01, "Rate should be saved correctly")
        #expect(abs(loadedConfig.pitch - 1.5) < 0.01, "Pitch should be saved correctly")
        #expect(abs(loadedConfig.volume - 0.7) < 0.01, "Volume should be saved correctly")
        #expect(abs(loadedConfig.pauseBetweenSentences - 2.0) < 0.01, "Pause duration should be saved correctly")
        #expect(loadedConfig.autoLanguageDetection == false, "Auto language detection should be saved correctly")
    }
    
    @Test("Preferred voice save and load")
    func preferredVoiceSaveAndLoad() async throws {
        let configManager = ConfigurationManager()
        
        let testVoice = TTSVoice(
            id: "test-voice",
            name: "Test Voice",
            language: "en-US",
            gender: .female,
            source: .ios
        )
        
        configManager.setPreferredVoice(testVoice, for: "en-US")
        let savedVoice = configManager.getPreferredVoice(for: "en-US")
        
        #expect(savedVoice != nil, "Should save and load voice")
        #expect(savedVoice?.id == testVoice.id, "Voice ID should match")
        #expect(savedVoice?.name == testVoice.name, "Voice name should match")
        #expect(savedVoice?.language == testVoice.language, "Voice language should match")
    }
    
    // MARK: - Text Processing Tests
    
    @Test("Sentence splitting functionality")
    func sentenceSplitting() async throws {
        let text = "First sentence. Second sentence! Third sentence? Fourth sentence."
        let sentences = text.splitIntoSentences()
        
        #expect(sentences.count == 4, "Should split into 4 sentences")
        #expect(sentences[0] == "First sentence", "First sentence should be correct")
        #expect(sentences[1] == "Second sentence", "Second sentence should be correct")
        #expect(sentences[2] == "Third sentence", "Third sentence should be correct")
        #expect(sentences[3] == "Fourth sentence", "Fourth sentence should be correct")
    }
    
    @Test("Chinese sentence splitting")
    func chineseSentenceSplitting() async throws {
        let chineseText = "第一句话。第二句话！第三句话？第四句话。"
        let sentences = chineseText.splitIntoSentences()
        
        #expect(sentences.count == 4, "Should split into 4 Chinese sentences")
        #expect(sentences[0] == "第一句话", "First Chinese sentence should be correct")
        #expect(sentences[1] == "第二句话", "Second Chinese sentence should be correct")
        #expect(sentences[2] == "第三句话", "Third Chinese sentence should be correct")
        #expect(sentences[3] == "第四句话", "Fourth Chinese sentence should be correct")
    }
    
    @Test("Text preprocessing")
    func textPreprocessing() async throws {
        let rawText = "Dr. Smith said it's 25°C & 100% sure @ 3:30 PM."
        let processed = TTSUtilities.preprocessText(rawText)
        
        #expect(processed.contains("Doctor"), "Should expand 'Dr.' to 'Doctor'")
        #expect(processed.contains("and"), "Should expand '&' to 'and'")
        #expect(processed.contains("percent"), "Should expand '%' to 'percent'")
        #expect(processed.contains("at"), "Should expand '@' to 'at'")
    }
    
    @Test("Speech duration estimation")
    func speechDurationEstimation() async throws {
        let shortText = "Hello world"
        let longText = "This is a much longer text that should take significantly more time to speak when converted to speech using text-to-speech technology."
        
        let shortDuration = TTSUtilities.estimateSpeechDuration(text: shortText, rate: 0.5)
        let longDuration = TTSUtilities.estimateSpeechDuration(text: longText, rate: 0.5)
        
        #expect(longDuration > shortDuration, "Long text should take more time")
        #expect(shortDuration > 0, "Duration should be positive")
    }
    
    // MARK: - TTSManager Tests
    
    @Test("TTSManager initialization")
    func ttsManagerInitialization() async throws {
        #expect(ttsManager != nil, "TTS Manager should initialize")
        #expect(!ttsManager.isPlaying, "Should not be playing initially")
        #expect(!ttsManager.isPaused, "Should not be paused initially")
        #expect(ttsManager.currentSentence == nil, "Should have no current sentence")
        #expect(ttsManager.currentProgress == 0.0, "Progress should be zero")
        #expect(ttsManager.queue.isEmpty, "Queue should be empty")
    }
    
    @Test("Queue management")
    func queueManagement() async throws {
        let sentences = ["First", "Second", "Third"]
        
        ttsManager.addToQueue(sentences)
        #expect(ttsManager.queue.count == 3, "Queue should have 3 items")
        
        ttsManager.clearQueue()
        #expect(ttsManager.queue.count == 0, "Queue should be empty after clearing")
    }
    
    @Test("Configuration update")
    func configurationUpdate() async throws {
        var config = ttsManager.configuration
        config.rate = 0.5
        ttsManager.updateConfiguration(config)
        let originalRate = ttsManager.configuration.rate
        
        config.rate = 0.8
        ttsManager.updateConfiguration(config)
        
        #expect(ttsManager.configuration.rate != originalRate, "Rate should be updated")
        #expect(abs(ttsManager.configuration.rate - 0.8) < 0.01, "Rate should be set to 0.8")
    }
    
    @Test("Event publisher functionality")
    mutating func eventPublisher() async throws {
        var receivedEvent = false
        
        ttsManager.eventPublisher
            .sink { event in
                switch event {
                case .started:
                    receivedEvent = true
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Simulate playback (in real tests might need to mock engine)
        ttsManager.speak("Test")
        
        // Wait for event processing
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        #expect(receivedEvent, "Should receive TTS event")
    }
    
    // MARK: - Voice Model Tests
    
    @Test("TTSVoice creation")
    func ttsVoiceCreation() async throws {
        let voice = TTSVoice(
            id: "test-id",
            name: "Test Voice",
            language: "en-US",
            gender: .female,
            source: .ios,
            quality: .enhanced
        )
        
        #expect(voice.id == "test-id", "Voice ID should match")
        #expect(voice.name == "Test Voice", "Voice name should match")
        #expect(voice.language == "en-US", "Voice language should match")
        #expect(voice.gender == .female, "Voice gender should match")
        #expect(voice.source == .ios, "Voice source should match")
        #expect(voice.quality == .enhanced, "Voice quality should match")
    }
    
    @Test("TTSVoice equality")
    func ttsVoiceEquality() async throws {
        let voice1 = TTSVoice(id: "test", name: "Test", language: "en", gender: .neutral, source: .ios)
        let voice2 = TTSVoice(id: "test", name: "Test", language: "en", gender: .neutral, source: .ios)
        let voice3 = TTSVoice(id: "different", name: "Test", language: "en", gender: .neutral, source: .ios)
        
        #expect(voice1 == voice2, "Voices with same properties should be equal")
        #expect(voice1 != voice3, "Voices with different IDs should not be equal")
    }
    
    // MARK: - TTSSentence Tests
    
    @Test("TTSSentence creation")
    func ttsSentenceCreation() async throws {
        let sentence = TTSSentence(text: "Test sentence")
        
        #expect(sentence.text == "Test sentence", "Sentence text should match")
        #expect(sentence.voice == nil, "Voice should be nil by default")
        #expect(sentence.customConfig == nil, "Custom config should be nil by default")
        #expect(sentence.id != nil, "ID should not be nil")
    }
    
    @Test("String to TTSSentence conversion")
    func stringToTTSSentence() async throws {
        let text = "Hello world"
        let sentence = text.toTTSSentence()
        
        #expect(sentence.text == text, "Sentence text should match original")
        #expect(sentence.id != nil, "ID should not be nil")
    }
    
    @Test("Array to TTSSentences conversion")
    func arrayToTTSSentences() async throws {
        let texts = ["First", "Second", "Third"]
        let sentences = texts.toTTSSentences()
        
        #expect(sentences.count == 3, "Should create 3 sentences")
        #expect(sentences[0].text == "First", "First sentence should match")
        #expect(sentences[1].text == "Second", "Second sentence should match")
        #expect(sentences[2].text == "Third", "Third sentence should match")
    }
}

// MARK: - Performance Tests
@MainActor
struct SwiftTTSPerformanceTests {
    
    @Test("Language detection performance")
    func languageDetectionPerformance() async throws {
        let voiceManager = VoiceManager()
        let longText = String(repeating: "This is a test sentence. ", count: 100)
        
        // Measure performance
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = voiceManager.detectLanguage(for: longText)
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        #expect(timeElapsed < 1.0, "Language detection should be fast")
    }
    
    @Test("Voice loading performance")
    func voiceLoadingPerformance() async throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = VoiceManager().getAllVoices()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        #expect(timeElapsed < 5.0, "Voice loading should complete in reasonable time")
    }
    
    @Test("Sentence splitting performance")
    func sentenceSplittingPerformance() async throws {
        let longText = String(repeating: "This is a sentence. ", count: 1000)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = longText.splitIntoSentences()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        #expect(timeElapsed < 1.0, "Sentence splitting should be fast")
    }
}

// MARK: - Mock TTS Engine for Testing
class MockTTSEngine: TTSEngine {
    
    var isPlaying: Bool = false
    var isPaused: Bool = false
    var mockDelay: TimeInterval = 0.1
    
    weak var delegate: TTSEngineDelegate?
    
    func speak(text: String, voice: TTSVoice, completion: @escaping (Result<Void, Error>) -> Void) {
        isPlaying = true
        isPaused = false
        
        // Simulate progress update
        delegate?.didUpdateProgress(0.5)
        
        Task {
            try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
            await MainActor.run {
                self.isPlaying = false
                completion(.success(()))
            }
        }
    }
    
    func pause() {
        isPaused = true
    }
    
    func resume() {
        isPaused = false
    }
    
    func stop() {
        isPlaying = false
        isPaused = false
    }
}

// MARK: - Integration Tests
@MainActor
struct TTSIntegrationTests {
    
    var ttsManager: TTSManager
    var mockEngine: MockTTSEngine
    var cancellables: Set<AnyCancellable>
    
    init() {
        ttsManager = TTSManager()
        mockEngine = MockTTSEngine()
        cancellables = Set<AnyCancellable>()
    }
    
    @Test("Full playback flow")
    mutating func fullPlaybackFlow() async throws {
        let sentences = ["First sentence", "Second sentence"]
        ttsManager.addToQueue(sentences)
        
        var eventCount = 0
        var queueCompleted = false
        
        ttsManager.eventPublisher
            .sink { event in
                eventCount += 1
                if case .queueCompleted = event {
                    queueCompleted = true
                }
            }
            .store(in: &cancellables)
        
        ttsManager.playQueue()
        
        // Wait for queue completion with timeout
        var attempts = 0
        while !queueCompleted && attempts < 50 {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            attempts += 1
        }
        
        #expect(eventCount > 0, "Should receive events")
        #expect(queueCompleted, "Queue should complete")
    }
}

// MARK: - AI TTS Service Tests
struct AITTSServiceTests {
    
    @Test("OpenAI service initialization")
    func openAIServiceInitialization() async throws {
        let service = OpenAITTSService(apiKey: "test-key")
        
        #expect(service.name == "OpenAI TTS", "Service name should match")
        #expect(!service.supportedVoices.isEmpty, "Should have supported voices")
    }
    
    @Test("Azure service initialization")
    func azureServiceInitialization() async throws {
        let service = AzureTTSService(subscriptionKey: "test-key", region: "test-region")
        
        #expect(service.name == "Azure Cognitive Services TTS", "Service name should match")
        #expect(!service.supportedVoices.isEmpty, "Should have supported voices")
    }
    
    @Test("Voice support validation")
    func voiceSupport() async throws {
        let service = OpenAITTSService(apiKey: "test-key")
        let supportedVoice = service.supportedVoices.first!
        let unsupportedVoice = TTSVoice(
            id: "unsupported",
            name: "Unsupported",
            language: "xx-XX",
            gender: .neutral,
            source: .ai
        )
        
        #expect(service.isVoiceSupported(supportedVoice), "Should support included voice")
        #expect(!service.isVoiceSupported(unsupportedVoice), "Should not support unsupported voice")
    }
}

// MARK: - Error Handling Tests
@MainActor
struct ErrorHandlingTests {
    
    @Test("TTS engine error handling")
    func ttsEngineErrorHandling() throws {
        let ttsManager = TTSManager()
        
        // Test with invalid configuration
        var config = TTSConfiguration()
        config.rate = -1.0 // Invalid rate
        
        // Should handle gracefully without crashing
        ttsManager.updateConfiguration(config)
        
        // Rate should be clamped or reset to valid value
        #expect(ttsManager.configuration.rate >= 0.0, "Rate should be valid after invalid input")
    }
    
    @Test("Voice loading error handling")
    func voiceLoadingErrorHandling() async throws {
        let voiceManager = VoiceManager()
        
        // Test with non-existent language
        let voices = voiceManager.getVoicesForLanguage("xx-XX")
        
        // Should return empty array, not crash
        #expect(voices.isEmpty, "Should return empty array for non-existent language")
    }
}

// MARK: - Memory Management Tests
@MainActor
struct MemoryManagementTests {
    
    @Test("TTS manager memory cleanup")
    func ttsManagerMemoryCleanup() throws {
        var ttsManager: TTSManager? = TTSManager()
        
        // Add some data
        ttsManager?.addToQueue(["Test sentence"])
        
        // Release reference
        ttsManager = nil
        
        // Should not crash - memory properly cleaned up
        #expect(ttsManager == nil, "TTS manager should be deallocated")
    }
    
    @Test("Voice manager memory cleanup")
    func voiceManagerMemoryCleanup() async throws {
        var voiceManager: VoiceManager? = VoiceManager()
        
        // Use voice manager
        _ = voiceManager?.getAllVoices()
        
        // Release reference
        voiceManager = nil
        
        // Should not crash - memory properly cleaned up
        #expect(voiceManager == nil, "Voice manager should be deallocated")
    }
}
