import Testing
import AVFoundation
import Combine
@testable import SwiftTTS

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
        let voices = voiceManager.getVoicesForLanguage(Language(code: .bcp47("xx-XX")))
        
        // Should return empty array, not crash
        #expect(voices.isEmpty, "Should return empty array for non-existent language")
    }
}
