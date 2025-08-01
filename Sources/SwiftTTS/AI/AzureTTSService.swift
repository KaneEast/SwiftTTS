import Foundation
import AVFoundation

// MARK: - Example Azure TTS Service Implementation
public class AzureTTSService: AITTSService {
    
    public let name = "Azure Cognitive Services TTS"
    
    private let subscriptionKey: String
    private let region: String
    
    public var supportedVoices: [TTSVoice] {
        // Azure支持大量语音，这里只列出一些示例
        return [
            TTSVoice(id: "en-US-AriaNeural", name: "Aria", language: "en-US", gender: .female, source: .ai, quality: .premium),
            TTSVoice(id: "en-US-DavisNeural", name: "Davis", language: "en-US", gender: .male, source: .ai, quality: .premium),
            TTSVoice(id: "zh-CN-XiaoxiaoNeural", name: "Xiaoxiao", language: "zh-CN", gender: .female, source: .ai, quality: .premium),
            TTSVoice(id: "zh-CN-YunyeNeural", name: "Yunye", language: "zh-CN", gender: .male, source: .ai, quality: .premium)
        ]
    }
    
    public init(subscriptionKey: String, region: String) {
        self.subscriptionKey = subscriptionKey
        self.region = region
    }
    
    public func synthesizeSpeech(
        text: String,
        voice: TTSVoice,
        configuration: TTSConfiguration,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        let endpoint = "https://\(region).tts.speech.microsoft.com/cognitiveservices/v1"
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(AITTSError.invalidResponse))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(subscriptionKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        request.setValue("application/ssml+xml", forHTTPHeaderField: "Content-Type")
        request.setValue("audio-24khz-48kbitrate-mono-mp3", forHTTPHeaderField: "X-Microsoft-OutputFormat")
        request.setValue("SwiftTTS/1.0", forHTTPHeaderField: "User-Agent")
        
        // 构建SSML
        let ssml = buildSSML(text: text, voice: voice, configuration: configuration)
        request.httpBody = ssml.data(using: .utf8)
        
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
    
    private func buildSSML(text: String, voice: TTSVoice, configuration: TTSConfiguration) -> String {
        let rate = Int((configuration.rate - 0.5) * 100) // 转换为百分比
        let pitch = String(format: "%.1f", configuration.pitch)
        
        return """
        <speak version='1.0' xml:lang='en-US'>
            <voice xml:lang='\(voice.language)' name='\(voice.id)'>
                <prosody rate='\(rate)%' pitch='\(pitch)'>
                    \(text)
                </prosody>
            </voice>
        </speak>
        """
    }
}
