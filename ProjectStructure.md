# SwiftTTS 项目结构

```
Sources
 ┣ SwiftTTS
 ┃ ┣ AI
 ┃ ┃ ┣ AITTSEngine.swift
 ┃ ┃ ┣ AITTSProtocols.swift
 ┃ ┃ ┣ AzureTTSService.swift
 ┃ ┃ ┗ OpenAITTSService.swift
 ┃ ┣ Configuration
 ┃ ┃ ┣ ConfigurationManager.swift
 ┃ ┃ ┣ TTSConfiguration.swift
 ┃ ┃ ┗ UserDefaults+TTS.swift
 ┃ ┣ Core
 ┃ ┃ ┣ Types
 ┃ ┃ ┃ ┣ Language.swift
 ┃ ┃ ┃ ┣ TTSEvent.swift
 ┃ ┃ ┃ ┣ TTSSentence.swift
 ┃ ┃ ┃ ┗ TTSVoice.swift
 ┃ ┃ ┣ TTSEngine.swift
 ┃ ┃ ┣ TTSManager.swift
 ┃ ┃ ┣ TTSModels.swift
 ┃ ┃ ┗ iOSTTSEngine.swift
 ┃ ┣ Extensions
 ┃ ┃ ┣ Array+TTS.swift
 ┃ ┃ ┣ String+TTS.swift
 ┃ ┃ ┗ View+TTS.swift
 ┃ ┣ Logging
 ┃ ┃ ┣ LogLevel.swift
 ┃ ┃ ┗ TTSLogger.swift
 ┃ ┣ UI
 ┃ ┃ ┣ TTSControlPanel.swift
 ┃ ┃ ┣ TTSProgressView.swift
 ┃ ┃ ┣ TTSSettingsView.swift
 ┃ ┃ ┗ TTSVoiceSelector.swift
 ┃ ┣ Utilities
 ┃ ┃ ┣ AudioUtils.swift
 ┃ ┃ ┗ LanguageUtils.swift
 ┃ ┣ Voice
 ┃ ┃ ┣ VoiceDetector.swift
 ┃ ┃ ┣ VoiceManager.swift
 ┃ ┃ ┗ VoicePreview.swift
 ┃ ┗ SwiftTTS.swift

```

## 模块说明



### AI 模块  
提供AI TTS服务的支持，包括各种AI服务的实现和协议定义。支持可插拔的AI服务架构。

### Configuration 模块
管理所有配置相关的功能，包括用户设置的保存和加载。

### Core 模块
包含TTS的核心功能，包括主要的管理器类、引擎协议和数据模型。这是整个库的基础。

### Extensions 模块
为系统类型提供TTS相关的扩展功能，使API更加便于使用。

### Logging 模块
提供日志功能，帮助调试和监控TTS功能的运行状况。

### UI 模块
提供SwiftUI组件，让开发者可以快速集成TTS功能到他们的应用中。

### Utilities 模块
提供各种工具函数，包括文本处理、语言工具和音频处理工具。

### Voice 模块
处理语音相关的功能，包括语音管理、语言检测和语音预览功能。

## 设计原则

1. **模块化**: 每个模块都有明确的职责，便于维护和扩展
2. **可扩展性**: 通过协议和抽象类支持新功能的添加
3. **可测试性**: 每个模块都有对应的测试，确保代码质量
4. **易用性**: 提供简单的API和丰富的示例
5. **性能优化**: 

## 依赖关系

```
TTSManager -> TTSEngine, VoiceManager, ConfigurationManager
VoiceManager -> LanguageDetector
AITTSEngine -> AITTSService
UI Components -> TTSManager
Extensions -> Core Models
```
