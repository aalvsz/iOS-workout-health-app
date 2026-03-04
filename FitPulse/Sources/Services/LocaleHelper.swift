import Foundation

enum AppLanguage {
    case english, spanish, french

    static var current: AppLanguage {
        guard let code = Locale.current.language.languageCode?.identifier else {
            return .english
        }
        switch code {
        case "es": return .spanish
        case "fr": return .french
        default: return .english
        }
    }

    var llmInstruction: String {
        switch self {
        case .english: return "Respond in English."
        case .spanish: return "Responde en espa\u{00F1}ol."
        case .french: return "R\u{00E9}ponds en fran\u{00E7}ais."
        }
    }

    var foodExtractionInstruction: String {
        switch self {
        case .english:
            return "Output food names in English."
        case .spanish:
            return "Output food names in Spanish (e.g. pollo, arroz, huevo)."
        case .french:
            return "Output food names in French (e.g. poulet, riz, oeuf)."
        }
    }

    var mealKeywords: [String] {
        switch self {
        case .english:
            return ["ate", "had", "eaten", "drank", "drunk"]
        case .spanish:
            return ["com\u{00ED}", "desayun\u{00E9}", "almorc\u{00E9}", "cen\u{00E9}", "tom\u{00E9}", "beb\u{00ED}"]
        case .french:
            return ["mang\u{00E9}", "pris", "bu", "d\u{00E9}jeun\u{00E9}", "d\u{00EE}n\u{00E9}", "go\u{00FB}t\u{00E9}"]
        }
    }
}
