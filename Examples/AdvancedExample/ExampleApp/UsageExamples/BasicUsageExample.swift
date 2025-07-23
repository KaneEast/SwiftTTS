import SwiftUI
import SwiftTTS
import Combine

@MainActor
class BasicUsageExample {
    
    private let ttsManager = TTSManager()
    private var cancellables = Set<AnyCancellable>()
    
    func setupTTS() {
        // Listen to TTS events
        ttsManager.eventPublisher
            .sink { event in
                switch event {
                case .started(let sentence):
                    print("Started playing: \(sentence)")
                case .completed(let sentence):
                    print("Completed playing: \(sentence)")
                case .error(let error):
                    print("Playback error: \(error)")
                case .queueCompleted:
                    print("Queue playback completed")
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    // Single sentence playback
    func speakSingleSentence() {
        ttsManager.speak("This is a simple voice test.")
    }
    
    // Queue playback
    func speakMultipleSentences() {
        let sentences = [
            "First sentence.",
            "Second sentence.",
            "Third sentence."
        ]
        
        ttsManager.addToQueue(sentences)
        ttsManager.playQueue()
    }
    
    // Use specific Voice
    func speakWithSpecificVoice() {
        let englishVoices = ttsManager.getVoicesForLanguage("en-US")
        if let voice = englishVoices.first {
            ttsManager.speak("Hello, World!", voice: voice)
        }
    }
    
    // Configure TTS parameters
    func configureAndSpeak() {
        var config = ttsManager.configuration
        config.rate = 0.3  // Slow speed
        config.pitch = 1.2 // Higher pitch
        config.pauseBetweenSentences = 1.0 // 1 second pause between sentences
        
        ttsManager.updateConfiguration(config)
        ttsManager.speak("This is a slow, high-pitched voice test.")
    }
}
