import Foundation
import SwiftUI
import Combine

public extension Array where Element == String {
    /// 将字符串数组转换为TTS句子数组
    func toTTSSentences(voice: TTSVoice? = nil, config: TTSConfiguration? = nil) -> [TTSSentence] {
        return self.map { $0.toTTSSentence(voice: voice, config: config) }
    }
}
