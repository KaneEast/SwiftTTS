import Foundation
import AVFoundation

public class OpenAITTSService: AITTSService {
    
    public let name = "OpenAI TTS"
    
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/audio/speech"
    
    public var supportedVoices: [TTSVoice] {
        return [
            TTSVoice(id: "alloy", name: "Alloy", language: "en-US", gender: .unspecified, source: .ai, quality: .premium),
            TTSVoice(id: "echo", name: "Echo", language: "en-US", gender: .male, source: .ai, quality: .premium),
            TTSVoice(id: "fable", name: "Fable", language: "en-US", gender: .unspecified, source: .ai, quality: .premium),
            TTSVoice(id: "onyx", name: "Onyx", language: "en-US", gender: .male, source: .ai, quality: .premium),
            TTSVoice(id: "nova", name: "Nova", language: "en-US", gender: .female, source: .ai, quality: .premium),
            TTSVoice(id: "shimmer", name: "Shimmer", language: "en-US", gender: .female, source: .ai, quality: .premium)
        ]
    }
    
    public init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    public func synthesizeSpeech(
        text: String,
        voice: TTSVoice,
        configuration: TTSConfiguration,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        guard let url = URL(string: baseURL) else {
            completion(.failure(AITTSError.invalidResponse))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "tts-1",
            "input": text,
            "voice": voice.id,
            "speed": configuration.rate
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(AITTSError.invalidResponse))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(AITTSError.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(AITTSError.invalidResponse))
                return
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                completion(.failure(AITTSError.serverError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(AITTSError.invalidResponse))
                return
            }
            
            completion(.success(data))
        }.resume()
    }
    
    public func isVoiceSupported(_ voice: TTSVoice) -> Bool {
        return supportedVoices.contains { $0.id == voice.id }
    }
}
