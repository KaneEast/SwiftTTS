import Foundation
import SwiftUI
import Combine

// MARK: - TTS SwiftUI View Components
@available(iOS 14.0, *)
public struct TTSControlPanel: View {
    
    @ObservedObject var manager: TTSManager
    @State private var showingVoiceSelector = false
    
    public init(manager: TTSManager) {
        self.manager = manager
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // 播放控制按钮
            HStack(spacing: 20) {
                Button(action: { manager.playQueue() }) {
                    Image(systemName: "play.fill")
                        .font(.title2)
                }
                .disabled(manager.queue.isEmpty || manager.isPlaying)
                
                Button(action: { manager.pause() }) {
                    Image(systemName: "pause.fill")
                        .font(.title2)
                }
                .disabled(!manager.isPlaying || manager.isPaused)
                
                Button(action: { manager.resume() }) {
                    Image(systemName: "play.fill")
                        .font(.title2)
                }
                .disabled(!manager.isPaused)
                
                Button(action: { manager.stop() }) {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                }
                .disabled(!manager.isPlaying)
            }
            
            // 进度条
            ProgressView(value: manager.currentProgress)
                .progressViewStyle(LinearProgressViewStyle())
            
            // 配置滑块
            VStack(spacing: 8) {
                HStack {
                    Text("Speed")
                    Spacer()
                    Text("\(manager.configuration.rate, specifier: "%.1f")")
                }
                Slider(value: Binding(
                    get: { manager.configuration.rate },
                    set: { newValue in
                        var config = manager.configuration
                        config.rate = newValue
                        manager.updateConfiguration(config)
                    }
                ), in: 0.1...1.0)
                
                HStack {
                    Text("Pitch")
                    Spacer()
                    Text("\(manager.configuration.pitch, specifier: "%.1f")")
                }
                Slider(value: Binding(
                    get: { manager.configuration.pitch },
                    set: { newValue in
                        var config = manager.configuration
                        config.pitch = newValue
                        manager.updateConfiguration(config)
                    }
                ), in: 0.5...2.0)
            }
            
            // Voice选择按钮
            Button("Select Voice") {
                showingVoiceSelector = true
            }
            .sheet(isPresented: $showingVoiceSelector) {
                TTSVoiceSelector(manager: manager)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}
