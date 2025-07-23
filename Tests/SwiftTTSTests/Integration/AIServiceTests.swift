import Testing
import AVFoundation
import Combine
@testable import SwiftTTS

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
            language: Language(code: .bcp47("xx-XX")),
            gender: .neutral,
            source: .ai
        )
        
        #expect(service.isVoiceSupported(supportedVoice), "Should support included voice")
        #expect(!service.isVoiceSupported(unsupportedVoice), "Should not support unsupported voice")
    }
}
