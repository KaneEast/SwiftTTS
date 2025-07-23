import Testing
import AVFoundation
import Combine
@testable import SwiftTTS

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
