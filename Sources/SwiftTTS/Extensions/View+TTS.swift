import Foundation
import SwiftUI
import Combine

public extension View {
    
    /// 添加TTS播放功能到任何View
    func ttsPlayable(
        text: String,
        manager: TTSManager,
        voice: TTSVoice? = nil,
        onLongPress: Bool = true
    ) -> some View {
        if onLongPress {
            return AnyView(
                self.onLongPressGesture {
                    manager.speak(text, voice: voice)
                }
            )
        } else {
            return AnyView(
                self.onTapGesture {
                    manager.speak(text, voice: voice)
                }
            )
        }
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
