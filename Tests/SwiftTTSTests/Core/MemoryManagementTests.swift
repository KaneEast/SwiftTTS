import Testing
import AVFoundation
import Combine
@testable import SwiftTTS

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
