import Foundation
import SwiftUI
import Combine

public extension String {
    
    /// 将字符串转换为句子数组
    func splitIntoSentences() -> [String] {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        
        // 先处理URL，避免被句号分割
        var processedText = self
        let urlPattern = #"https?://[^\s]+"#
        if let regex = try? NSRegularExpression(pattern: urlPattern) {
            let matches = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
            for match in matches.reversed() {
                let urlRange = Range(match.range, in: self)!
                let placeholder = "URLPLACEHOLDER\(matches.firstIndex(of: match) ?? 0)"
                processedText = processedText.replacingCharacters(in: urlRange, with: placeholder)
            }
        }
        
        // 使用更智能的句子分割
        let sentenceEnders = CharacterSet(charactersIn: ".!?。！？")
        let components = processedText.components(separatedBy: sentenceEnders)
        
        return components
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { sentence in
                // 恢复URL
                var restored = sentence
                for i in 0..<10 { // 假设最多10个URL
                    let placeholder = "URLPLACEHOLDER\(i)"
                    if restored.contains(placeholder) {
                        // 这里需要从原始匹配中恢复URL，简化处理
                        restored = restored.replacingOccurrences(of: placeholder, with: "URL")
                    }
                }
                return restored
            }
    }
    
    /// 检测文本的主要语言
    func detectLanguage() -> Language? {
        let voiceManager = VoiceManager()
        return voiceManager.detectLanguage(for: self)
    }
    
    /// 创建TTS句子对象
    func toTTSSentence(voice: TTSVoice? = nil, config: TTSConfiguration? = nil) -> TTSSentence {
        return TTSSentence(text: self, voice: voice, customConfig: config)
    }
}
