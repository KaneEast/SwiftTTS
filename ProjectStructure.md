# SwiftTTS 项目结构

```
SwiftTTS/
├── Package.swift                          # Swift Package 配置文件
├── README.md                             # 项目说明文档
├── Sources/
│   └── SwiftTTS/
│       ├── Core/                         # 核心功能模块
│       │   ├── TTSManager.swift          # TTS管理器主类
│       │   ├── TTSEngine.swift           # TTS引擎协议和基础实现
│       │   ├── iOSTTSEngine.swift        # iOS原生TTS引擎
│       │   └── TTSModels.swift           # 数据模型定义
│       │
│       ├── AI/                           # AI TTS服务模块
│       │   ├── AITTSEngine.swift         # AI TTS引擎基类
│       │   ├── OpenAITTSService.swift    # OpenAI TTS服务实现
│       │   ├── AzureTTSService.swift     # Azure TTS服务实现
│       │   └── AITTSProtocols.swift      # AI服务协议定义
│       │
│       ├── Voice/                        # 语音管理模块
│       │   ├── VoiceManager.swift        # 语音管理器
│       │   ├── VoiceDetector.swift       # 语言检测器
│       │   └── VoicePreview.swift        # 语音预览功能
│       │
│       ├── Configuration/                # 配置管理模块
│       │   ├── ConfigurationManager.swift # 配置管理器
│       │   ├── UserDefaults+TTS.swift    # UserDefaults扩展
│       │   └── TTSConfiguration.swift    # 配置结构定义
│       │
│       ├── Utilities/                    # 工具类模块
│       │   ├── TTSUtilities.swift        # TTS工具函数
│       │   ├── TextProcessor.swift       # 文本处理器
│       │   ├── LanguageUtils.swift       # 语言工具类
│       │   └── AudioUtils.swift          # 音频工具类
│       │
│       ├── Extensions/                   # 扩展功能模块
│       │   ├── String+TTS.swift          # String扩展
│       │   ├── Array+TTS.swift           # Array扩展
│       │   └── View+TTS.swift            # SwiftUI View扩展
│       │
│       ├── UI/                           # UI组件模块
│       │   ├── TTSControlPanel.swift     # TTS控制面板
│       │   ├── TTSVoiceSelector.swift    # 语音选择器
│       │   ├── TTSProgressView.swift     # 播放进度视图
│       │   └── TTSSettingsView.swift     # TTS设置视图
│       │
│       ├── Accessibility/                # 可访问性模块
│       │   ├── AccessibilitySupport.swift # 可访问性支持
│       │   └── VoiceOverIntegration.swift # VoiceOver集成
│       │
│       ├── Logging/                      # 日志模块
│       │   ├── TTSLogger.swift           # TTS日志器
│       │   └── LogLevel.swift            # 日志级别定义
│       │
│       └── SwiftTTS.swift                # 主要导出文件
│
├── Tests/
│   └── SwiftTTSTests/
│       ├── Core/
│       │   ├── TTSManagerTests.swift     # TTS管理器测试
│       │   └── TTSEngineTests.swift      # TTS引擎测试
│       │
│       ├── Voice/
│       │   ├── VoiceManagerTests.swift   # 语音管理器测试
│       │   └── LanguageDetectionTests.swift # 语言检测测试
│       │
│       ├── Utilities/
│       │   ├── TextProcessorTests.swift  # 文本处理测试
│       │   └── TTSUtilitiesTests.swift   # 工具函数测试
│       │
│       ├── Integration/
│       │   ├── PlaybackFlowTests.swift   # 播放流程集成测试
│       │   └── AIServiceTests.swift      # AI服务集成测试
│       │
│       ├── Mocks/
│       │   ├── MockTTSEngine.swift       # 模拟TTS引擎
│       │   └── MockAIService.swift       # 模拟AI服务
│       │
│       └── SwiftTTSTests.swift           # 主测试文件
│
├── Examples/                             # 示例项目
│   ├── BasicExample/                     # 基础使用示例
│   │   ├── BasicExampleApp.swift
│   │   └── ContentView.swift
│   │
│   ├── AdvancedExample/                  # 高级功能示例
│   │   ├── AdvancedExampleApp.swift
│   │   ├── DocumentReaderView.swift
│   │   └── TTSSettingsView.swift
│   │
│   └── AIIntegrationExample/             # AI集成示例
│       ├── AIExampleApp.swift
│       └── AIVoiceTestView.swift
│
├── Documentation/                        # 详细文档
│   ├── GettingStarted.md                # 快速入门指南
│   ├── Configuration.md                 # 配置文档
│   ├── AIIntegration.md                 # AI集成指南
│   ├── SwiftUIIntegration.md            # SwiftUI集成指南
│   ├── Troubleshooting.md               # 故障排除
│   └── API/                             # API文档
│       ├── TTSManager.md
│       ├── VoiceManager.md
│       └── AITTSEngine.md
│
└── Resources/                            # 资源文件
    ├── Assets/                           # 资产文件
    │   └── Icons/                        # 图标文件
    ├── Localization/                     # 本地化文件
    │   ├── en.lproj/
    │   ├── zh-Hans.lproj/
    │   └── ja.lproj/
    └── SampleTexts/                      # 示例文本文件
        ├── english_samples.txt
        ├── chinese_samples.txt
        └── multilingual_samples.txt
```

## 模块说明

### Core 模块
包含TTS的核心功能，包括主要的管理器类、引擎协议和数据模型。这是整个库的基础。

### AI 模块  
提供AI TTS服务的支持，包括各种AI服务的实现和协议定义。支持可插拔的AI服务架构。

### Voice 模块
处理语音相关的功能，包括语音管理、语言检测和语音预览功能。

### Configuration 模块
管理所有配置相关的功能，包括用户设置的保存和加载。

### Utilities 模块
提供各种工具函数，包括文本处理、语言工具和音频处理工具。

### Extensions 模块
为系统类型提供TTS相关的扩展功能，使API更加便于使用。

### UI 模块
提供SwiftUI组件，让开发者可以快速集成TTS功能到他们的应用中。

### Accessibility 模块
确保TTS功能与iOS可访问性功能良好集成。

### Logging 模块
提供日志功能，帮助调试和监控TTS功能的运行状况。

## 设计原则

1. **模块化**: 每个模块都有明确的职责，便于维护和扩展
2. **可扩展性**: 通过协议和抽象类支持新功能的添加
3. **可测试性**: 每个模块都有对应的测试，确保代码质量
4. **易用性**: 提供简单的API和丰富的示例
5. **性能优化**: 关键路径进行了性能优化
6. **可访问性**: 全面支持iOS可访问性功能

## 依赖关系

```
TTSManager -> TTSEngine, VoiceManager, ConfigurationManager
VoiceManager -> LanguageDetector
AITTSEngine -> AITTSService
UI Components -> TTSManager
Extensions -> Core Models
```

这种结构确保了清晰的依赖关系和良好的代码组织。