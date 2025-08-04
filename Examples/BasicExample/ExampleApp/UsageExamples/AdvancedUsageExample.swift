import SwiftUI
import SwiftTTS
import Combine

@MainActor
class AdvancedUsageExample {
    
    private let ttsManager = TTSManager()
    
    func setupWithAIService() {
        // Add OpenAI TTS service (requires API key)
        let openAIService = OpenAITTSService(apiKey: "your-api-key")
        let aiEngine = AITTSEngine(service: openAIService)
        ttsManager.registerAIEngine(aiEngine)
        
        // Switch to AI engine
        ttsManager.switchToEngine(ofType: AITTSEngine.self)
        
        // Use AI voice playback
        let aiVoices = openAIService.supportedVoices
        if let voice = aiVoices.first {
            ttsManager.speak("This is an AI-generated voice.", voice: voice)
        }
    }
    
    func multiLanguagePlayback() {
        let texts = [
            "Hello, this is English.",
            "Hello, this is Chinese.",
            "こんにちは、これは日本語です。",
            "Bonjour, c'est du français."
        ]
        
        // Auto-detect language and select appropriate Voice
        let sentences = texts.map { text -> TTSSentence in
            if let language = text.detectLanguage() {
                let voices = ttsManager.getVoicesForLanguage(language)
                let voice = voices.first
                return TTSSentence(text: text, voice: voice)
            }
            return TTSSentence(text: text)
        }
        
        ttsManager.addToQueue(sentences)
        ttsManager.playQueue()
    }
    
//    func smartTextProcessing() {
//        let rawText = """
//        Dr. Smith said that the meeting is at 3:30 PM. 
//        The temperature is 25°C today. 
//        You can reach us at info@example.com or call 123-456-7890.
//        """
//        
//        // Preprocess text
//        let processedText = TTSUtilities.preprocessText(rawText)
//        
//        // Split into sentences
//        let sentences = processedText.splitIntoSentences()
//        
//        // Estimate playback time
//        let estimatedDuration = TTSUtilities.estimateSpeechDuration(
//            text: processedText,
//            rate: ttsManager.configuration.rate
//        )
//        
//        print("Estimated playback time: \(estimatedDuration) seconds")
//        
//        ttsManager.addToQueue(sentences)
//        ttsManager.playQueue()
//    }
}
