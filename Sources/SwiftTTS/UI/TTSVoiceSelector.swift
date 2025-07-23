import Foundation
import SwiftUI
import Combine

@available(iOS 14.0, *)
public struct TTSVoiceSelector: View {    
    @ObservedObject var manager: TTSManager
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedVoice: TTSVoice?
    
    public init(manager: TTSManager) {
        self.manager = manager
        self._selectedVoice = State(initialValue: manager.configuration.preferredVoice)
    }
    
    public var body: some View {
        NavigationView {
            List {
                ForEach(groupedVoices.keys.sorted(), id: \.self) { language in
                    Section(header: Text(language)) {
                        ForEach(groupedVoices[language] ?? []) { voice in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(voice.name)
                                        .font(.headline)
                                    Text("\(voice.gender.rawValue.capitalized) • \(voice.quality.rawValue.capitalized)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedVoice?.id == voice.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                                
                                Button("Preview") {
                                    previewVoice(voice)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedVoice = voice
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Voice")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if let voice = selectedVoice {
                            manager.setPreferredVoice(voice)
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private var groupedVoices: [String: [TTSVoice]] {
        Dictionary(grouping: manager.availableVoices) { $0.language.id }
    }
    
    private func previewVoice(_ voice: TTSVoice) {
        let voiceManager = VoiceManager()
        voiceManager.previewVoice(voice) { result in
            // 处理预览结果
        }
    }
}
