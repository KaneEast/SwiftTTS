#  Locale and Language

Currently this Package uses language by string.
Todo: create feature for easy use for language by below apple document.

https://developer.apple.com/documentation/foundation/locale
https://developer.apple.com/documentation/foundation/locale/language-swift.struct
https://developer.apple.com/documentation/avfaudio/avspeechsynthesisvoice


Check below code as reference.
Create wrapper type for Locale.language. if must
and provide easy API for existing TTSVoice, e.g, listing Nations and group avalaible voices for each.

Before begin, describe whats plan to do. 


Sources/SwiftTTS/Core/Types/TTSVoice.swift

```swiftr
open class AVSpeechSynthesisVoice : NSObject, NSSecureCoding, @unchecked Sendable
    open class func speechVoices() -> [AVSpeechSynthesisVoice]
```
```swiftr
import Foundation

public struct Language: Hashable, Sendable, Identifiable {
    public var id: String { code.bcp47 }
    
    public static var current: Language {
        Language(locale: Locale.current)
    }

    /// List of all available languages on the device.
    public static let all: [Language] =
        Locale.availableIdentifiers
            .map { Language(code: .bcp47($0)) }

    public enum Code: Hashable, Sendable {
        case bcp47(String)

        public var bcp47: String {
            switch self {
            case let .bcp47(code):
                return code
            }
        }

        public func removingRegion() -> Code {
            .bcp47(String(bcp47.prefix { $0 != "-" && $0 != "_" }))
        }
    }

    public let code: Code

    public var locale: Locale { Locale(identifier: code.bcp47) }

    public func localizedDescription(in locale: Locale = Locale.current) -> String {
        locale.localizedString(forIdentifier: code.bcp47) ?? code.bcp47
    }
    
    public func flagWithLocalizedDescription(in locale: Locale = Locale.current) -> String {
        (flagEmoji() ?? "") + (locale.localizedString(forIdentifier: code.bcp47) ?? code.bcp47)
    }

    public func localizedLanguage(in targetLocale: Locale = Locale.current) -> String? {
        locale.languageCode.flatMap { targetLocale.localizedString(forLanguageCode: $0) }
    }

    public func localizedRegion(in targetLocale: Locale = Locale.current) -> String? {
        locale.regionCode.flatMap { targetLocale.localizedString(forRegionCode: $0) }
    }

    public init(code: Code) {
        self.code = code
    }

    public init(locale: Locale) {
        self.init(code: .bcp47(locale.identifier))
    }

    public func removingRegion() -> Language {
        Language(code: code.removingRegion())
    }
}

extension Language: CustomStringConvertible {
    public var description: String {
        code.bcp47
    }
}

extension Language: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(code: .bcp47(value))
    }
}

extension Language: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let code = try container.decode(String.self)
        self.init(code: .bcp47(code))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(code.bcp47)
    }
}

extension Language {
    public func flagEmoji() -> String? {
        // Handle cases where region codes do not have specific flags
        let flagExceptions: [String: String] = [
            "ar-001": "🌍", // Arabic (World)
            "ar-EG": "🇪🇬"  // Egypt-specific
        ]
        
        // Return predefined exceptions if available
        if let predefinedFlag = flagExceptions[code.bcp47] {
            return predefinedFlag
        }
        
        guard let regionCode = locale.regionCode else { return nil }

        // Convert country code (e.g., "JP", "US") into flag emoji
        return regionCode.unicodeScalars.compactMap {
            UnicodeScalar(127397 + $0.value) // 127397 is the base for regional flags in Unicode
        }.map { String($0) }.joined()
    }
}

```





Planned Implementation:

  1. Create Language Type - Implement the Language struct from TODO.md
   with:
    - BCP47 code support
    - Locale integration
    - Flag emoji generation
    - Localized descriptions
  2. Update TTSVoice - Replace String language property with Language
  type
  3. Enhance VoiceManager - Add APIs for:
    - Grouping voices by nations/regions
    - Better language detection using Locale.Language
    - Filtering voices by language families
  4. Maintain Compatibility - Ensure backward compatibility with
  existing string-based APIs