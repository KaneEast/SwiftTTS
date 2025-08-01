import Foundation
import AVFoundation
import NaturalLanguage

// MARK: - Voice Preview
extension VoiceManager {
    
    public func previewVoice(_ voice: TTSVoice, completion: @escaping (Result<Void, Error>) -> Void) {
        let previewText = getPreviewText(for: voice.language)
        let engine = iOSTTSEngine()
        engine.speak(text: previewText, voice: voice, completion: completion)
    }
    
    private func getPreviewText(for language: Language) -> String {
        let previewTexts: [String: String] = [
            "zh-CN": "这是一个语音测试示例。",
            "zh-TW": "這是一個語音測試示例。",
            "en-US": "This is a voice preview sample.",
            "en-GB": "This is a voice preview sample.",
            "ja-JP": "これは音声プレビューのサンプルです。",
            "ko-KR": "이것은 음성 미리보기 샘플입니다.",
            "fr-FR": "Ceci est un échantillon d'aperçu vocal.",
            "de-DE": "Dies ist ein Sprachvorschau-Beispiel.",
            "es-ES": "Esta es una muestra de vista previa de voz.",
            "it-IT": "Questo è un campione di anteprima vocale.",
            "pt-BR": "Esta é uma amostra de prévia de voz.",
            "ru-RU": "Это образец предварительного просмотра голоса.",
            "ar-SA": "هذا نموذج لمعاينة الصوت.",
            "th-TH": "นี่คือตัวอย่างการแสดงตัวอย่างเสียง",
            "vi-VN": "Đây là một mẫu xem trước giọng nói."
        ]
        
        let languageCode = language.code.bcp47
        
        if let text = previewTexts[languageCode] {
            return text
        }
        
        if let languagePrefix = language.languageCode {
            for (key, text) in previewTexts {
                if key.hasPrefix(languagePrefix) {
                    return text
                }
            }
        }
        
        return previewTexts["en-US"] ?? "This is a voice preview sample."
    }
}
