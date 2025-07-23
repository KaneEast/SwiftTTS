import Testing
import AVFoundation
import Combine
@testable import SwiftTTS

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
