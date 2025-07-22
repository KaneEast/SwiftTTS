import SwiftUI
import SwiftTTS
import Combine

// MARK: - Basic Usage Example.
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

// MARK: - Advanced Usage Example
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
    
    func smartTextProcessing() {
        let rawText = """
        Dr. Smith said that the meeting is at 3:30 PM. 
        The temperature is 25°C today. 
        You can reach us at info@example.com or call 123-456-7890.
        """
        
        // Preprocess text
        let processedText = TTSUtilities.preprocessText(rawText)
        
        // Split into sentences
        let sentences = processedText.splitIntoSentences()
        
        // Estimate playback time
        let estimatedDuration = TTSUtilities.estimateSpeechDuration(
            text: processedText,
            rate: ttsManager.configuration.rate
        )
        
        print("Estimated playback time: \(estimatedDuration) seconds")
        
        ttsManager.addToQueue(sentences)
        ttsManager.playQueue()
    }
}

// MARK: - SwiftUI Integration Example
@available(iOS 14.0, *)
struct TTSExampleView: View {
    
    @StateObject private var ttsManager = TTSManager()
    @State private var inputText = "Please enter text to read aloud..."
    @State private var isShowingVoiceSelector = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Text input area
                VStack(alignment: .leading) {
                    Text("Input Text")
                        .font(.headline)
                    
                    TextEditor(text: $inputText)
                        .frame(height: 120)
                        .border(Color.gray, width: 1)
                        .ttsPlayable(
                            text: inputText,
                            manager: ttsManager,
                            onLongPress: true
                        )
                }
                
                // TTS Control Panel
                TTSControlPanel(manager: ttsManager)
                
                // Action buttons
                VStack(spacing: 12) {
                    HStack {
                        Button("Read Text") {
                            ttsManager.speak(inputText)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Add to Queue") {
                            let sentences = inputText.splitIntoSentences()
                            ttsManager.addToQueue(sentences)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    HStack {
                        Button("Clear Queue") {
                            ttsManager.clearQueue()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Select Voice") {
                            isShowingVoiceSelector = true
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                // Status display
                VStack(alignment: .leading, spacing: 8) {
                    Text("Status Information")
                        .font(.headline)
                    
                    HStack {
                        Circle()
                            .fill(ttsManager.isPlaying ? .green : .gray)
                            .frame(width: 12, height: 12)
                        Text(ttsManager.isPlaying ? "Playing" : "Stopped")
                    }
                    
                    if let currentSentence = ttsManager.currentSentence {
                        Text("Current: \(currentSentence.text)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Queue: \(ttsManager.queue.count) sentences")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("SwiftTTS Example")
            .sheet(isPresented: $isShowingVoiceSelector) {
                TTSVoiceSelector(manager: ttsManager)
            }
        }
    }
}

// MARK: - Document Reader Example
@available(iOS 14.0, *)
struct DocumentReaderView: View {
    
    @StateObject private var ttsManager = TTSManager()
    @State private var document = """
    SwiftTTS is a powerful iOS text-to-speech library.
    
    It supports iOS native TTS and AI TTS services.
    
    You can easily play single or multiple sentences, and supports pause, resume and other operations.
    
    The library also provides rich configuration options, including speech rate, pitch, voice selection, etc.
    """
    
    @State private var currentParagraph = 0
    @State private var isReading = false
    
    var paragraphs: [String] {
        document.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    var body: some View {
        VStack {
            // Document content
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(paragraphs.enumerated()), id: \.offset) { index, paragraph in
                        Text(paragraph)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(currentParagraph == index ? Color.blue.opacity(0.1) : Color.clear)
                            )
                            .onTapGesture {
                                currentParagraph = index
                                ttsManager.speak(paragraph)
                            }
                    }
                }
                .padding()
            }
            
            // Reading controls
            VStack {
                HStack {
                    Button("Start Reading") {
                        startReading()
                    }
                    .disabled(isReading)
                    
                    Button("Pause") {
                        ttsManager.pause()
                    }
                    .disabled(!isReading)
                    
                    Button("Resume") {
                        ttsManager.resume()
                    }
                    .disabled(!ttsManager.isPaused)
                    
                    Button("Stop") {
                        stopReading()
                    }
                }
                
                TTSControlPanel(manager: ttsManager)
            }
            .padding()
        }
        .onReceive(ttsManager.eventPublisher) { event in
            handleTTSEvent(event)
        }
    }
    
    private func startReading() {
        isReading = true
        currentParagraph = 0
        
        let sentences = paragraphs.flatMap { $0.splitIntoSentences() }
        ttsManager.addToQueue(sentences)
        ttsManager.playQueue()
    }
    
    private func stopReading() {
        isReading = false
        currentParagraph = 0
        ttsManager.stop()
        ttsManager.clearQueue()
    }
    
    private func handleTTSEvent(_ event: TTSEvent) {
        switch event {
        case .started(let sentence):
            // Find current playing paragraph
            for (index, paragraph) in paragraphs.enumerated() {
                if paragraph.contains(sentence) {
                    currentParagraph = index
                    break
                }
            }
        case .queueCompleted:
            isReading = false
            currentParagraph = 0
        default:
            break
        }
    }
}

// MARK: - App Example Entry
@available(iOS 14.0, *)
@main
struct TTSExampleApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                TTSExampleView()
                    .tabItem {
                        Image(systemName: "speaker.wave.2")
                        Text("Basic Example")
                    }
                
                DocumentReaderView()
                    .tabItem {
                        Image(systemName: "doc.text")
                        Text("Document Reading")
                    }
            }
        }
    }
}

// MARK: - Usage Instructions
/*
 Quick start using SwiftTTS:

 1. Basic playback:
    let ttsManager = TTSManager()
    ttsManager.speak("Hello, World!")

 2. Queue playback:
    ttsManager.addToQueue(["First sentence", "Second sentence", "Third sentence"])
    ttsManager.playQueue()

 3. Configure parameters:
    var config = ttsManager.configuration
    config.rate = 0.8  // Speech rate
    config.pitch = 1.2 // Pitch
    ttsManager.updateConfiguration(config)

 4. Select voice:
    let voices = ttsManager.getVoicesForLanguage("en-US")
    if let voice = voices.first {
        ttsManager.setPreferredVoice(voice)
    }

 5. Add AI service:
    let openAIService = OpenAITTSService(apiKey: "your-key")
    let aiEngine = AITTSEngine(service: openAIService)
    ttsManager.registerAIEngine(aiEngine)

 6. SwiftUI integration:
    Text("Click to read")
        .ttsPlayable(text: "Hello", manager: ttsManager)
*/
