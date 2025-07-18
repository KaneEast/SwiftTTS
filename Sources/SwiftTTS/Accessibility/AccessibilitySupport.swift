//import Foundation
//import UIKit
//import SwiftUI
//
//// MARK: - Accessibility Support
//public class TTSAccessibilitySupport {
//    
//    public static let shared = TTSAccessibilitySupport()
//    
//    private init() {
//        setupAccessibilityNotifications()
//    }
//    
//    // MARK: - VoiceOver Integration
//    public var isVoiceOverRunning: Bool {
//        return UIAccessibility.isVoiceOverRunning
//    }
//    
//    public var isSwitchControlRunning: Bool {
//        return UIAccessibility.isSwitchControlRunning
//    }
//    
//    public var isAssistiveTouchRunning: Bool {
//        return UIAccessibility.isAssistiveTouchRunning
//    }
//    
//    // MARK: - Accessibility Configuration
//    public func configureForAccessibility(_ manager: TTSManager) {
//        if isVoiceOverRunning {
//            // 当VoiceOver运行时，调整TTS配置
//            var config = manager.configuration
//            config.rate = max(0.3, config.rate * 0.8) // 稍微降低语速
//            config.pauseBetweenSentences = max(1.0, config.pauseBetweenSentences * 1.5) // 增加句间停顿
//            manager.updateConfiguration(config)
//            
//            TTSInfo("TTS configured for VoiceOver compatibility")
//        }
//    }
//    
//    // MARK: - Smart Accessibility Integration
//    public func shouldPauseForAccessibility(_ manager: TTSManager) -> Bool {
//        // 如果用户正在使用VoiceOver或其他辅助功能，可能需要暂停TTS
//        if isVoiceOverRunning && UIAccessibility.isVoiceOverRunning {
//            // 检查VoiceOver是否正在说话
//            return true
//        }
//        return false
//    }
//    
//    // MARK: - Accessibility Announcements
//    public func announceToAccessibility(_ message: String, priority: UIAccessibility.AnnouncementPriority = .medium) {
//        DispatchQueue.main.async {
//            UIAccessibility.post(notification: .announcement, argument: message)
//        }
//    }
//    
//    public func announcePlaybackState(_ state: TTSPlaybackState) {
//        let message: String
//        switch state {
//        case .playing:
//            message = NSLocalizedString("TTS播放已开始", comment: "TTS playback started")
//        case .paused:
//            message = NSLocalizedString("TTS播放已暂停", comment: "TTS playback paused")
//        case .stopped:
//            message = NSLocalizedString("TTS播放已停止", comment: "TTS playback stopped")
//        case .completed:
//            message = NSLocalizedString("TTS播放已完成", comment: "TTS playback completed")
//        }
//        
//        announceToAccessibility(message, priority: .medium)
//    }
//    
//    // MARK: - Accessibility Notifications
//    private func setupAccessibilityNotifications() {
//        NotificationCenter.default.addObserver(
//            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
//            object: nil,
//            queue: .main
//        ) { [weak self] _ in
//            self?.handleVoiceOverStatusChange()
//        }
//        
//        NotificationCenter.default.addObserver(
//            forName: UIAccessibility.switchControlStatusDidChangeNotification,
//            object: nil,
//            queue: .main
//        ) { [weak self] _ in
//            self?.handleSwitchControlStatusChange()
//        }
//    }
//    
//    private func handleVoiceOverStatusChange() {
//        TTSInfo("VoiceOver status changed: \(isVoiceOverRunning)")
//        
//        // 通知所有TTS管理器调整配置
//        NotificationCenter.default.post(
//            name: .ttsAccessibilityConfigurationChanged,
//            object: nil
//        )
//    }
//    
//    private func handleSwitchControlStatusChange() {
//        TTSInfo("Switch Control status changed: \(isSwitchControlRunning)")
//    }
//    
//    // MARK: - Accessibility Labels and Hints
//    public func accessibilityLabel(for voice: TTSVoice) -> String {
//        let genderText = voice.gender == .female ? "女性" : voice.gender == .male ? "男性" : "中性"
//        let qualityText = voice.quality == .premium ? "高品质" : voice.quality == .enhanced ? "增强" : "标准"
//        
//        return "\(voice.name)，\(genderText)声音，\(qualityText)质量，语言：\(voice.language)"
//    }
//    
//    public func accessibilityHint(for action: TTSAccessibilityAction) -> String {
//        switch action {
//        case .play:
//            return NSLocalizedString("双击开始播放文本", comment: "Double tap to start playing text")
//        case .pause:
//            return NSLocalizedString("双击暂停播放", comment: "Double tap to pause playback")
//        case .stop:
//            return NSLocalizedString("双击停止播放", comment: "Double tap to stop playback")
//        case .selectVoice:
//            return NSLocalizedString("双击选择不同的语音", comment: "Double tap to select a different voice")
//        case .adjustSpeed:
//            return NSLocalizedString("使用滑动手势调整播放速度", comment: "Use swipe gestures to adjust playback speed")
//        }
//    }
//}
//
//// MARK: - Accessibility Action Types
//public enum TTSAccessibilityAction {
//    case play
//    case pause
//    case stop
//    case selectVoice
//    case adjustSpeed
//}
//
//// MARK: - Playback State
//public enum TTSPlaybackState {
//    case playing
//    case paused
//    case stopped
//    case completed
//}
//
//// MARK: - Notification Names
//public extension Notification.Name {
//    static let ttsAccessibilityConfigurationChanged = Notification.Name("TTSAccessibilityConfigurationChanged")
//}
//
//// MARK: - SwiftUI Accessibility Extensions
//@available(iOS 14.0, *)
//public extension View {
//    
//    func ttsAccessible(
//        label: String,
//        hint: String? = nil,
//        action: @escaping () -> Void
//    ) -> some View {
//        self
//            .accessibilityLabel(label)
//            .accessibilityHint(hint ?? "")
//            .accessibilityAction {
//                action()
//            }
//    }
//    
//    func ttsVoiceAccessible(_ voice: TTSVoice) -> some View {
//        let accessibilitySupport = TTSAccessibilitySupport.shared
//        return self
//            .accessibilityLabel(accessibilitySupport.accessibilityLabel(for: voice))
//            .accessibilityHint(accessibilitySupport.accessibilityHint(for: .selectVoice))
//    }
//    
//    func ttsControlAccessible(
//        action: TTSAccessibilityAction,
//        isEnabled: Bool = true
//    ) -> some View {
//        let accessibilitySupport = TTSAccessibilitySupport.shared
//        let hint = accessibilitySupport.accessibilityHint(for: action)
//        
//        return self
//            .accessibilityHint(hint)
//            .accessibilityAddTraits(isEnabled ? .button : [.button, .notEnabled])
//    }
//}
//
//// MARK: - TTSManager Accessibility Extensions
//public extension TTSManager {
//    
//    func configureAccessibility() {
//        TTSAccessibilitySupport.shared.configureForAccessibility(self)
//        
//        // 监听可访问性配置变化
//        NotificationCenter.default.addObserver(
//            forName: .ttsAccessibilityConfigurationChanged,
//            object: nil,
//            queue: .main
//        ) { [weak self] _ in
//            guard let self = self else { return }
//            TTSAccessibilitySupport.shared.configureForAccessibility(self)
//        }
//    }
//    
//    func announcePlaybackStateChange() {
//        let state: TTSPlaybackState
//        if isPlaying && !isPaused {
//            state = .playing
//        } else if isPaused {
//            state = .paused
//        } else {
//            state = .stopped
//        }
//        
//        TTSAccessibilitySupport.shared.announcePlaybackState(state)
//    }
//}
//
//// MARK: - Accessibility-Aware TTS Controls
//@available(iOS 14.0, *)
//public struct AccessibleTTSControlPanel: View {
//    
//    @ObservedObject var manager: TTSManager
//    private let accessibilitySupport = TTSAccessibilitySupport.shared
//    
//    public init(manager: TTSManager) {
//        self.manager = manager
//    }
//    
//    public var body: some View {
//        VStack(spacing: 16) {
//            // 播放控制按钮
//            HStack(spacing: 20) {
//                Button(action: {
//                    manager.playQueue()
//                    manager.announcePlaybackStateChange()
//                }) {
//                    Image(systemName: "play.fill")
//                        .font(.title2)
//                }
//                .disabled(manager.queue.isEmpty || manager.isPlaying)
//                .ttsControlAccessible(action: .play, isEnabled: !manager.queue.isEmpty && !manager.isPlaying)
//                
//                Button(action: {
//                    manager.pause()
//                    manager.announcePlaybackStateChange()
//                }) {
//                    Image(systemName: "pause.fill")
//                        .font(.title2)
//                }
//                .disabled(!manager.isPlaying || manager.isPaused)
//                .ttsControlAccessible(action: .pause, isEnabled: manager.isPlaying && !manager.isPaused)
//                
//                Button(action: {
//                    manager.stop()
//                    manager.announcePlaybackStateChange()
//                }) {
//                    Image(systemName: "stop.fill")
//                        .font(.title2)
//                }
//                .disabled(!manager.isPlaying)
//                .ttsControlAccessible(action: .stop, isEnabled: manager.isPlaying)
//            }
//            
//            // 进度条
//            ProgressView(value: manager.currentProgress)
//                .progressViewStyle(LinearProgressViewStyle())
//                .accessibilityLabel("播放进度")
//                .accessibilityValue("\(Int(manager.currentProgress * 100))%")
//            
//            // 配置滑块
//            VStack(spacing: 8) {
//                HStack {
//                    Text("播放速度")
//                    Spacer()
//                    Text("\(manager.configuration.rate, specifier: "%.1f")")
//                }
//                
//                Slider(value: Binding(
//                    get: { manager.configuration.rate },
//                    set: { newValue in
//                        var config = manager.configuration
//                        config.rate = newValue
//                        manager.updateConfiguration(config)
//                        
//                        // 为可访问性用户提供反馈
//                        if accessibilitySupport.isVoiceOverRunning {
//                            accessibilitySupport.announceToAccessibility("播放速度设置为 \(String(format: "%.1f", newValue))")
//                        }
//                    }
//                ), in: 0.1...1.0)
//                .ttsControlAccessible(action: .adjustSpeed)
//                .accessibilityLabel("播放速度")
//                .accessibilityValue("\(String(format: "%.1f", manager.configuration.rate))")
//            }
//        }
//        .padding()
//        .background(Color.secondary.opacity(0.1))
//        .cornerRadius(12)
//        .accessibilityElement(children: .contain)
//        .accessibilityLabel("TTS控制面板")
//    }
//}
//
//// MARK: - Accessibility Testing Support
//#if DEBUG
//public class TTSAccessibilityTester {
//    
//    public static func testAccessibilityLabels(voices: [TTSVoice]) {
//        let support = TTSAccessibilitySupport.shared
//        
//        for voice in voices {
//            let label = support.accessibilityLabel(for: voice)
//            print("Voice: \(voice.name) -> Accessibility Label: \(label)")
//        }
//    }
//    
//    public static func testAccessibilityHints() {
//        let support = TTSAccessibilitySupport.shared
//        let actions: [TTSAccessibilityAction] = [.play, .pause, .stop, .selectVoice, .adjustSpeed]
//        
//        for action in actions {
//            let hint = support.accessibilityHint(for: action)
//            print("Action: \(action) -> Hint: \(hint)")
//        }
//    }
//    
//    public static func simulateVoiceOverEnvironment() {
//        // 这个方法在实际应用中应该通过Accessibility Inspector来测试
//        print("请使用Xcode的Accessibility Inspector来测试VoiceOver兼容性")
//    }
//}
//#endif
