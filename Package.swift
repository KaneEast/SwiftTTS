// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftTTS",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "SwiftTTS",
            targets: ["SwiftTTS"]
        ),
    ],
    dependencies: [
        // 可以添加外部依赖，如网络请求库
    ],
    targets: [
        .target(
            name: "SwiftTTS",
            dependencies: []
        ),
        .testTarget(
            name: "SwiftTTSTests",
            dependencies: ["SwiftTTS"]
        ),
    ]
)
