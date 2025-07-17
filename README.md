# SwiftTTS - Powerful iOS Text-to-Speech Library (Under Developing)

SwiftTTS is a feature-rich, easy-to-use iOS text-to-speech Swift Package that supports seamless switching between iOS native TTS and AI TTS services.

## ✨ Core Features

### 🎯 TTS Engine Support
- **iOS Native TTS**: Uses AVSpeechSynthesizer, supports all iOS built-in voices
- **AI TTS Extension**: Supports OpenAI, Azure, and other AI TTS services
- **Engine Switching**: Dynamic runtime switching between TTS engines

### 🎵 Playback Control
- **Continuous Playback**: Supports queue playback of sentence lists
- **Playback Control**: Play, pause, resume, stop, skip
- **Single Sentence Playback**: Quick playback of individual text
- **Progress Callbacks**: Real-time playback progress and status notifications

### 🗣️ Voice Configuration
- **Voice Selection**: Supports iOS built-in voices and AI service voices
- **Playback Parameters**: Fine-tuning of speed, pitch, and volume
- **Sentence Intervals**: Configurable pause time between sentences
- **Language Detection**: Automatic language detection and voice matching

### 👤 User Experience
- **Voice List**: Display all available voices with preview support
- **Preference Storage**: Save user's preferred default voice
- **SwiftUI Integration**: Provides ready-to-use UI components

## 🚀 Quick Start

### Installation

Add Swift Package in Xcode:
```
https://github.com/KaneEast/SwiftTTS
```

### Basic Usage

```swift
import SwiftTTS

// Create TTS manager
let ttsManager = TTSManager()

// Single sentence playback
ttsManager.speak("Hello, World!")

// Queue playback
ttsManager.addToQueue(["First sentence", "Second sentence", "Third sentence"])
ttsManager.playQueue()

// Playback control
ttsManager.pause()
ttsManager.resume()
ttsManager.stop()
```

### Configuration Parameters

```swift
var config = ttsManager.configuration
config.rate = 0.8               // Speech rate (0.1-1.0)
config.pitch = 1.2              // Pitch (0.5-2.0)
config.volume = 0.9             // Volume (0.0-1.0)
config.pauseBetweenSentences = 1.0  // Interval between sentences
config.autoLanguageDetection = true // Auto language detection

ttsManager.updateConfiguration(config)
```

### Voice Selection

```swift
// Get voices for specific language
let chineseVoices = ttsManager.getVoicesForLanguage("zh-CN")
let englishVoices = ttsManager.getVoicesForLanguage("en-US")

// Set preferred voice
if let voice = chineseVoices.first {
    ttsManager.setPreferredVoice(voice)
}

// Play with specified voice
ttsManager.speak("Hello, World!", voice: englishVoices.first)
```

### Event Listening

```swift
import Combine

var cancellables = Set<AnyCancellable>()

ttsManager.eventPublisher
    .sink { event in
        switch event {
        case .started(let sentence):
            print("Started playing: \(sentence)")
        case .completed(let sentence):
            print("Completed playing: \(sentence)")
        case .paused:
            print("Paused")
        case .resumed:
            print("Resumed")
        case .stopped:
            print("Stopped")
        case .error(let error):
            print("Error: \(error)")
        case .queueCompleted:
            print("Queue playback completed")
        case .progressChanged(let progress):
            print("Playback progress: \(progress)")
        }
    }
    .store(in: &cancellables)
```

## 🤖 AI TTS Service Integration

### OpenAI TTS

```swift
// Create OpenAI service
let openAIService = OpenAITTSService(apiKey: "your-api-key")
let aiEngine = AITTSEngine(service: openAIService)

// Register AI engine
ttsManager.registerAIEngine(aiEngine)

// Switch to AI engine
ttsManager.switchToEngine(ofType: AITTSEngine.self)

// Use AI voice
let aiVoices = openAIService.supportedVoices
if let voice = aiVoices.first {
    ttsManager.speak("This is AI-generated speech!", voice: voice)
}
```

### Azure TTS

```swift
// Create Azure service
let azureService = AzureTTSService(
    subscriptionKey: "your-key",
    region: "your-region"
)
let azureEngine = AITTSEngine(service: azureService)

ttsManager.registerAIEngine(azureEngine)
```

### Custom AI Service

```swift
// Implement AITTSService protocol
class CustomTTSService: AITTSService {
    var name: String = "Custom TTS"
    var supportedVoices: [TTSVoice] = [...]

    func synthesizeSpeech(
        text: String,
        voice: TTSVoice,
        configuration: TTSConfiguration,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        // Implement custom TTS logic
    }

    func isVoiceSupported(_ voice: TTSVoice) -> Bool {
        // Check voice support
    }
}
```

## 🎨 SwiftUI Integration

### TTS Control Panel

```swift
import SwiftUI

struct ContentView: View {
    @StateObject private var ttsManager = TTSManager()

    var body: some View {
        VStack {
            TTSControlPanel(manager: ttsManager)

            TTSVoiceSelector(manager: ttsManager)
        }
    }
}
```

### Text Reading Feature

```swift
Text("Tap to read this text")
    .ttsPlayable(
        text: "Hello, World!",
        manager: ttsManager,
        onLongPress: true  // Long press trigger
    )
```

### Complete Example

```swift
struct DocumentReaderView: View {
    @StateObject private var ttsManager = TTSManager()
    @State private var text = "Enter text to read..."

    var body: some View {
        VStack {
            TextEditor(text: $text)
                .frame(height: 200)

            TTSControlPanel(manager: ttsManager)

            HStack {
                Button("Read") {
                    ttsManager.speak(text)
                }

                Button("Add to Queue") {
                    let sentences = text.splitIntoSentences()
                    ttsManager.addToQueue(sentences)
                }
            }
        }
        .padding()
    }
}
```

## 🛠️ Advanced Features

### Text Preprocessing

```swift
// Smart text preprocessing
let rawText = "Dr. Smith said it's 25°C at 3:30 PM."
let processedText = TTSUtilities.preprocessText(rawText)
// Output: "Doctor Smith said it's twenty five degrees celsius at three thirty PM."

// Sentence splitting
let sentences = text.splitIntoSentences()

// Duration estimation
let duration = TTSUtilities.estimateSpeechDuration(
    text: text,
    rate: ttsManager.configuration.rate
)
```

### Multi-language Support

```swift
let multiLanguageTexts = [
    "Hello, this is English.",
    "你好，这是中文。",
    "こんにちは、これは日本語です。",
    "Bonjour, c'est du français."
]

// Auto language detection and voice matching
let sentences = multiLanguageTexts.map { text -> TTSSentence in
    if let language = text.detectLanguage() {
        let voice = ttsManager.getVoicesForLanguage(language).first
        return TTSSentence(text: text, voice: voice)
    }
    return TTSSentence(text: text)
}

ttsManager.addToQueue(sentences)
ttsManager.playQueue()
```

### Playback History Management

```swift
// Get playback history
let history = configManager.loadPlaybackHistory()

// Add history item
let historyItem = PlaybackHistoryItem(
    text: "Played text",
    voice: selectedVoice,
    duration: 5.0
)
configManager.addToPlaybackHistory(historyItem)
```

## 📱 Supported Platforms

- iOS 14.0+
- macOS 11.0+
- Swift 5.9+

## 🎯 Planned Extensions

### Coming Soon
- [ ] **Audio Effects**: Echo, reverb, and other audio effects
- [ ] **Background Music**: Support for background music mixing
- [ ] **Audio Export**: Export TTS results as audio files
- [ ] **Bookmark System**: Save playback positions
- [ ] **SSML Support**: Speech Synthesis Markup Language support

### Future Plans
- [ ] **Emotional Intonation**: Adjust intonation based on text content
- [ ] **Visualization**: Audio waveform display
- [ ] **Subtitle Sync**: Text highlighting follows playback
- [ ] **Gesture Control**: Support for gesture operations
- [ ] **More AI Services**: Google Cloud TTS, Amazon Polly, etc.

## 📄 License

MIT License

## 🤝 Contributing

Issues and Pull Requests are welcome!

## 📞 Support

For questions or suggestions, please submit an Issue or send an email to: support@example.com

---

**SwiftTTS** - Give your app a natural and smooth voice experience!