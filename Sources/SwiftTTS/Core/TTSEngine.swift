import Foundation
import AVFoundation
import Combine

// MARK: - TTS Engine Protocol
public protocol TTSEngine {
    func speak(text: String, voice: TTSVoice, completion: @escaping (Result<Void, Error>) -> Void)
    func pause()
    func resume()
    func stop()
    var isPlaying: Bool { get }
    var isPaused: Bool { get }
}
