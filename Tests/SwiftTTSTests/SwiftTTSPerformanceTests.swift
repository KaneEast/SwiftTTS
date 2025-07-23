import Testing
import AVFoundation
import Combine
@testable import SwiftTTS

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
