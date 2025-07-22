import Foundation

public struct Language: Hashable, Sendable, Identifiable, Comparable {
    public var id: String { code.bcp47 }
    
    public static var current: Language {
        Language(locale: Locale.current)
    }

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
        let flagExceptions: [String: String] = [
            "ar-001": "🌍",
            "ar-EG": "🇪🇬"
        ]
        
        if let predefinedFlag = flagExceptions[code.bcp47] {
            return predefinedFlag
        }
        
        guard let regionCode = locale.regionCode else { return nil }

        return regionCode.unicodeScalars.compactMap {
            UnicodeScalar(127397 + $0.value)
        }.map { String($0) }.joined()
    }
}

public extension Language {
    var languageCode: String? {
        locale.languageCode
    }
    
    var regionCode: String? {
        locale.regionCode
    }
    
    var scriptCode: String? {
        locale.scriptCode
    }
    
    func matches(_ other: Language) -> Bool {
        languageCode == other.languageCode
    }
    
    func matchesExactly(_ other: Language) -> Bool {
        code.bcp47 == other.code.bcp47
    }
    
    static func groupedByRegion(_ languages: [Language]) -> [String: [Language]] {
        Dictionary(grouping: languages) { language in
            language.regionCode ?? "Unknown"
        }
    }
    
    static func groupedByLanguage(_ languages: [Language]) -> [String: [Language]] {
        Dictionary(grouping: languages) { language in
            language.languageCode ?? "Unknown"
        }
    }
    
    public static func < (lhs: Language, rhs: Language) -> Bool {
        lhs.code.bcp47 < rhs.code.bcp47
    }
}