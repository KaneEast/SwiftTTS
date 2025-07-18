import XCTest
import AVFoundation
import Combine
@testable import SwiftTTS

@MainActor
final class SwiftTTSTests: XCTestCase {
    
    var ttsManager: TTSManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        ttsManager = TTSManager()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        ttsManager = nil
        cancellables = nil
    }
    
    // MARK: - Voice Management Tests
    
    func testGetAllVoices() throws {
        let voices = ttsManager.availableVoices
        XCTAssertFalse(voices.isEmpty, "应该有可用的语音")
        
        // 检查是否包含英语和中文语音
        let englishVoices = voices.filter { $0.language.hasPrefix("en") }
        let chineseVoices = voices.filter { $0.language.hasPrefix("zh") }
        
        XCTAssertFalse(englishVoices.isEmpty, "应该有英语语音")
        // 中文语音可能不在所有设备上都有，所以不强制要求
    }
    
    func testGetVoicesForLanguage() throws {
        let englishVoices = ttsManager.getVoicesForLanguage("en-US")
        XCTAssertFalse(englishVoices.isEmpty, "应该有英语语音")
        
        for voice in englishVoices {
            XCTAssertTrue(voice.language.hasPrefix("en"), "语音语言应该匹配")
        }
    }
    
    func testLanguageDetection() throws {
        let voiceManager = VoiceManager()
        
        let englishText = "Hello, this is a test."
        let detectedLanguage = voiceManager.detectLanguage(for: englishText)
        XCTAssertNotNil(detectedLanguage, "应该能检测到语言")
        XCTAssertTrue(detectedLanguage?.hasPrefix("en") == true, "应该检测为英语")
        
        let chineseText = "你好，这是一个测试。"
        let chineseLanguage = voiceManager.detectLanguage(for: chineseText)
        XCTAssertNotNil(chineseLanguage, "应该能检测到中文")
        XCTAssertTrue(chineseLanguage?.hasPrefix("zh") == true, "应该检测为中文")
    }
    
    // MARK: - Configuration Tests
    
    func testConfigurationSaveAndLoad() throws {
        let configManager = ConfigurationManager()
        
        var config = TTSConfiguration()
        config.rate = 0.8
        config.pitch = 1.5
        config.volume = 0.7
        config.pauseBetweenSentences = 2.0
        config.autoLanguageDetection = false
        
        configManager.saveConfiguration(config)
        let loadedConfig = configManager.loadConfiguration()
        
        XCTAssertEqual(loadedConfig.rate, 0.8, accuracy: 0.01)
        XCTAssertEqual(loadedConfig.pitch, 1.5, accuracy: 0.01)
        XCTAssertEqual(loadedConfig.volume, 0.7, accuracy: 0.01)
        XCTAssertEqual(loadedConfig.pauseBetweenSentences, 2.0, accuracy: 0.01)
        XCTAssertFalse(loadedConfig.autoLanguageDetection)
    }
    
    func testPreferredVoiceSaveAndLoad() throws {
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
        
        XCTAssertNotNil(savedVoice)
        XCTAssertEqual(savedVoice?.id, testVoice.id)
        XCTAssertEqual(savedVoice?.name, testVoice.name)
        XCTAssertEqual(savedVoice?.language, testVoice.language)
    }
    
    // MARK: - Text Processing Tests
    
    func testSentenceSplitting() throws {
        let text = "First sentence. Second sentence! Third sentence? Fourth sentence."
        let sentences = text.splitIntoSentences()
        
        XCTAssertEqual(sentences.count, 4)
        XCTAssertEqual(sentences[0], "First sentence")
        XCTAssertEqual(sentences[1], "Second sentence")
        XCTAssertEqual(sentences[2], "Third sentence")
        XCTAssertEqual(sentences[3], "Fourth sentence")
    }
    
    func testChineseSentenceSplitting() throws {
        let chineseText = "第一句话。第二句话！第三句话？第四句话。"
        let sentences = chineseText.splitIntoSentences()
        
        XCTAssertEqual(sentences.count, 4)
        XCTAssertEqual(sentences[0], "第一句话")
        XCTAssertEqual(sentences[1], "第二句话")
        XCTAssertEqual(sentences[2], "第三句话")
        XCTAssertEqual(sentences[3], "第四句话")
    }
    
    func testTextPreprocessing() throws {
        let rawText = "Dr. Smith said it's 25°C & 100% sure @ 3:30 PM."
        let processed = TTSUtilities.preprocessText(rawText)
        
        XCTAssertTrue(processed.contains("Doctor"))
        XCTAssertTrue(processed.contains("and"))
        XCTAssertTrue(processed.contains("percent"))
        XCTAssertTrue(processed.contains("at"))
    }
    
    func testSpeechDurationEstimation() throws {
        let shortText = "Hello world"
        let longText = "This is a much longer text that should take significantly more time to speak when converted to speech using text-to-speech technology."
        
        let shortDuration = TTSUtilities.estimateSpeechDuration(text: shortText, rate: 0.5)
        let longDuration = TTSUtilities.estimateSpeechDuration(text: longText, rate: 0.5)
        
        XCTAssertGreaterThan(longDuration, shortDuration)
        XCTAssertGreaterThan(shortDuration, 0)
    }
    
    // MARK: - TTSManager Tests
    
    func testTTSManagerInitialization() throws {
        XCTAssertNotNil(ttsManager)
        XCTAssertFalse(ttsManager.isPlaying)
        XCTAssertFalse(ttsManager.isPaused)
        XCTAssertNil(ttsManager.currentSentence)
        XCTAssertEqual(ttsManager.currentProgress, 0.0)
        XCTAssertTrue(ttsManager.queue.isEmpty)
    }
    
    func testQueueManagement() throws {
        let sentences = ["First", "Second", "Third"]
        
        ttsManager.addToQueue(sentences)
        XCTAssertEqual(ttsManager.queue.count, 3)
        
        ttsManager.clearQueue()
        XCTAssertEqual(ttsManager.queue.count, 0)
    }
    
    func testConfigurationUpdate() throws {
        var config = ttsManager.configuration
        let originalRate = config.rate
        
        config.rate = 0.8
        ttsManager.updateConfiguration(config)
        
        XCTAssertNotEqual(ttsManager.configuration.rate, originalRate)
        XCTAssertEqual(ttsManager.configuration.rate, 0.8, accuracy: 0.01)
    }
    
    func testEventPublisher() throws {
        let expectation = XCTestExpectation(description: "TTS事件应该被发布")
        
        ttsManager.eventPublisher
            .sink { event in
                switch event {
                case .started:
                    expectation.fulfill()
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // 模拟播放（在真实测试中可能需要模拟引擎）
        ttsManager.speak("Test")
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Voice Model Tests
    
    func testTTSVoiceCreation() throws {
        let voice = TTSVoice(
            id: "test-id",
            name: "Test Voice",
            language: "en-US",
            gender: .female,
            source: .ios,
            quality: .enhanced
        )
        
        XCTAssertEqual(voice.id, "test-id")
        XCTAssertEqual(voice.name, "Test Voice")
        XCTAssertEqual(voice.language, "en-US")
        XCTAssertEqual(voice.gender, .female)
        XCTAssertEqual(voice.source, .ios)
        XCTAssertEqual(voice.quality, .enhanced)
    }
    
    func testTTSVoiceEquality() throws {
        let voice1 = TTSVoice(id: "test", name: "Test", language: "en", gender: .neutral, source: .ios)
        let voice2 = TTSVoice(id: "test", name: "Test", language: "en", gender: .neutral, source: .ios)
        let voice3 = TTSVoice(id: "different", name: "Test", language: "en", gender: .neutral, source: .ios)
        
        XCTAssertEqual(voice1, voice2)
        XCTAssertNotEqual(voice1, voice3)
    }
    
    // MARK: - TTSSentence Tests
    
    func testTTSSentenceCreation() throws {
        let sentence = TTSSentence(text: "Test sentence")
        
        XCTAssertEqual(sentence.text, "Test sentence")
        XCTAssertNil(sentence.voice)
        XCTAssertNil(sentence.customConfig)
        XCTAssertNotNil(sentence.id)
    }
    
    func testStringToTTSSentence() throws {
        let text = "Hello world"
        let sentence = text.toTTSSentence()
        
        XCTAssertEqual(sentence.text, text)
        XCTAssertNotNil(sentence.id)
    }
    
    func testArrayToTTSSentences() throws {
        let texts = ["First", "Second", "Third"]
        let sentences = texts.toTTSSentences()
        
        XCTAssertEqual(sentences.count, 3)
        XCTAssertEqual(sentences[0].text, "First")
        XCTAssertEqual(sentences[1].text, "Second")
        XCTAssertEqual(sentences[2].text, "Third")
    }
    
    // MARK: - Performance Tests
    
    func testLanguageDetectionPerformance() throws {
        let voiceManager = VoiceManager()
        let longText = String(repeating: "This is a test sentence. ", count: 100)
        
        measure {
            _ = voiceManager.detectLanguage(for: longText)
        }
    }
    
    func testVoiceLoadingPerformance() throws {
        measure {
            _ = VoiceManager().getAllVoices()
        }
    }
    
    func testSentenceSplittingPerformance() throws {
        let longText = String(repeating: "This is a sentence. ", count: 1000)
        
        measure {
            _ = longText.splitIntoSentences()
        }
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
        
        // 模拟进度更新
        delegate?.didUpdateProgress(0.5)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + mockDelay) {
            self.isPlaying = false
            completion(.success(()))
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
final class TTSIntegrationTests: XCTestCase {
    
    var ttsManager: TTSManager!
    var mockEngine: MockTTSEngine!
    var cacellables =  Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        ttsManager = TTSManager()
        mockEngine = MockTTSEngine()
        // 在实际实现中，需要添加注册mock引擎的方法
    }
    
    func testFullPlaybackFlow() throws {
        let expectation = XCTestExpectation(description: "完整播放流程")
        
        let sentences = ["First sentence", "Second sentence"]
        ttsManager.addToQueue(sentences)
        
        var eventCount = 0
        ttsManager.eventPublisher
            .sink { event in
                eventCount += 1
                if case .queueCompleted = event {
                    expectation.fulfill()
                }
            }
            .store(in: &cacellables)
        
        ttsManager.playQueue()
        
        wait(for: [expectation], timeout: 5.0)
        XCTAssertGreaterThan(eventCount, 0)
    }
}

// MARK: - AI TTS Service Tests
final class AITTSServiceTests: XCTestCase {
    
    func testOpenAIServiceInitialization() throws {
        let service = OpenAITTSService(apiKey: "test-key")
        
        XCTAssertEqual(service.name, "OpenAI TTS")
        XCTAssertFalse(service.supportedVoices.isEmpty)
    }
    
    func testAzureServiceInitialization() throws {
        let service = AzureTTSService(subscriptionKey: "test-key", region: "test-region")
        
        XCTAssertEqual(service.name, "Azure Cognitive Services TTS")
        XCTAssertFalse(service.supportedVoices.isEmpty)
    }
    
    func testVoiceSupport() throws {
        let service = OpenAITTSService(apiKey: "test-key")
        let supportedVoice = service.supportedVoices.first!
        let unsupportedVoice = TTSVoice(
            id: "unsupported",
            name: "Unsupported",
            language: "xx-XX",
            gender: .neutral,
            source: .ai
        )
        
        XCTAssertTrue(service.isVoiceSupported(supportedVoice))
        XCTAssertFalse(service.isVoiceSupported(unsupportedVoice))
    }
}
