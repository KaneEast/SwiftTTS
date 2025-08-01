import Foundation
import AVFoundation

// MARK: - AI TTS Service Protocol
public protocol AITTSService {
    var name: String { get }
    var supportedVoices: [TTSVoice] { get }
    
    func synthesizeSpeech(
        text: String,
        voice: TTSVoice,
        configuration: TTSConfiguration,
        completion: @escaping (Result<Data, Error>) -> Void
    )
    
    func isVoiceSupported(_ voice: TTSVoice) -> Bool
}

// MARK: - AI TTS Error Types
public enum AITTSError: Error, LocalizedError {
    case networkError(Error)
    case authenticationFailed
    case invalidResponse
    case voiceNotSupported
    case quotaExceeded
    case serverError(Int)
    case audioConversionFailed
    
    public var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .authenticationFailed:
            return "Authentication failed"
        case .invalidResponse:
            return "Invalid response from server"
        case .voiceNotSupported:
            return "Voice not supported"
        case .quotaExceeded:
            return "Quota exceeded"
        case .serverError(let code):
            return "Server error: \(code)"
        case .audioConversionFailed:
            return "Audio conversion failed"
        }
    }
}
