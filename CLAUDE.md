# SwiftTTS - Claude Development Guide

## Project Overview
SwiftTTS is a Swift Package Manager library for iOS/macOS text-to-speech functionality that supports both native iOS TTS (AVSpeechSynthesizer) and AI TTS services (OpenAI, Azure, etc.).

## Project Structure
- **Sources/SwiftTTS/**: Main library code
- **Tests/**: Unit tests
- **Package.swift**: Swift Package Manager configuration
- **README.md**: User documentation (English)
- **.gitignore**: Git exclusions for SPM project

## Development Guidelines

### Code Style
- Follow Swift naming conventions (camelCase for variables/functions, PascalCase for types)
- Use proper access control (public for API, internal/private for implementation)
- Add comprehensive documentation comments for public APIs
- Keep functions focused and concise

### Testing
- Write unit tests for all public APIs
- Use XCTest framework
- Mock external dependencies (AI services, network calls)
- Test both success and failure scenarios

### Dependencies
- Minimize external dependencies
- Use only iOS/macOS system frameworks when possible
- For AI services, use URLSession for network requests
- Consider Combine for reactive programming

### Key Components Expected
1. **TTSManager**: Main coordinator class
2. **TTSConfiguration**: Configuration data structure
3. **TTSVoice**: Voice representation
4. **TTSEngine**: Protocol for different TTS engines
5. **NativeTTSEngine**: iOS AVSpeechSynthesizer wrapper
6. **AITTSEngine**: AI service wrapper
7. **TTSEvent**: Event system for callbacks
8. **SwiftUI Components**: UI components for voice selection and control

### Build Commands
Since this is a Swift Package Manager project:
- Build: `swift build`
- Test: `swift test`
- Clean: `swift package clean`

### Platform Support
- iOS 17.0+
- Swift 5.9+

### Important Notes
- This is a library project, not an app
- Focus on clean public APIs
- Handle errors gracefully
- Support both programmatic and SwiftUI usage
- Consider memory management for audio playback
- Handle background app states properly

## Common Development Tasks

### Adding New Features
1. Design public API first
2. Add to appropriate source files
3. Write unit tests
4. Update documentation
5. Consider SwiftUI integration

### Debugging Issues
- Use Xcode's debugging tools
- Test on physical devices for audio issues
- Check iOS permissions for speech
- Monitor memory usage during playback

### Performance Considerations
- Lazy loading of voices
- Efficient queue management
- Proper cleanup of audio resources
- Background thread usage for AI services
