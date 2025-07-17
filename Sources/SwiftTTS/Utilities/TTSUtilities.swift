import Foundation
import SwiftUI
import Combine

public class TTSUtilities {
    
    /// 智能文本预处理
    public static func preprocessText(_ text: String) -> String {
        var processed = text
        
        // 处理数字
        processed = processNumbers(processed)
        
        // 处理缩写
        processed = processAbbreviations(processed)
        
        // 处理特殊符号
        processed = processSpecialCharacters(processed)
        
        // 清理多余的空格和换行
        processed = processed.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        processed = processed.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return processed
    }
    
    /// 估算语音时长
    public static func estimateSpeechDuration(text: String, rate: Float = 0.5) -> TimeInterval {
        let wordsPerMinute: Double = 150 // 平均语速
        let adjustedWPM = wordsPerMinute * Double(rate * 2) // 根据语速调整
        
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        
        return Double(wordCount) / adjustedWPM * 60.0
    }
    
    /// 创建阅读友好的文本格式
    public static func formatForReading(_ text: String) -> String {
        var formatted = text
        
        // 在句号后添加适当的停顿标记
        formatted = formatted.replacingOccurrences(of: ". ", with: ". \n")
        
        // 处理段落
        formatted = formatted.replacingOccurrences(of: "\n\n", with: "\n\n\n")
        
        return formatted
    }
    
    // MARK: - Private Helper Methods
    private static func processNumbers(_ text: String) -> String {
        var processed = text
        
        // 简单的数字处理，实际实现可以更复杂
        let numberPattern = #"\b\d+\b"#
        
        if let regex = try? NSRegularExpression(pattern: numberPattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            
            for match in matches.reversed() {
                if let range = Range(match.range, in: text) {
                    let numberString = String(text[range])
                    if let number = Int(numberString) {
                        let spelledOut = NumberFormatter.spellOut.string(from: NSNumber(value: number)) ?? numberString
                        processed = processed.replacingCharacters(in: range, with: spelledOut)
                    }
                }
            }
        }
        
        return processed
    }
    
    private static func processAbbreviations(_ text: String) -> String {
        let abbreviations: [String: String] = [
            "Dr.": "Doctor",
            "Mr.": "Mister",
            "Mrs.": "Missus",
            "Ms.": "Miss",
            "Prof.": "Professor",
            "etc.": "et cetera",
            "e.g.": "for example",
            "i.e.": "that is",
            "vs.": "versus"
        ]
        
        var processed = text
        for (abbrev, expansion) in abbreviations {
            processed = processed.replacingOccurrences(of: abbrev, with: expansion)
        }
        
        return processed
    }
    
    private static func processSpecialCharacters(_ text: String) -> String {
        let specialChars: [String: String] = [
            "&": "and",
            "@": "at",
            "#": "hashtag",
            "%": "percent",
            "$": "dollar",
            "©": "copyright",
            "®": "registered",
            "™": "trademark"
        ]
        
        var processed = text
        for (char, replacement) in specialChars {
            processed = processed.replacingOccurrences(of: char, with: replacement)
        }
        
        return processed
    }
}

// MARK: - Number Formatter Extension
private extension NumberFormatter {
    static let spellOut: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        return formatter
    }()
}

// MARK: - Convenience Initializers
public extension TTSManager {
    
    /// 便利初始化方法，支持快速配置
    convenience init(
        preferredLanguage: String? = nil,
        defaultRate: Float = 0.5,
        defaultPitch: Float = 1.0
    ) {
        self.init()
        
        var config = self.configuration
        config.rate = defaultRate
        config.pitch = defaultPitch
        
        if let language = preferredLanguage {
            let voices = getVoicesForLanguage(language)
            config.preferredVoice = voices.first
        }
        
        updateConfiguration(config)
    }
}
