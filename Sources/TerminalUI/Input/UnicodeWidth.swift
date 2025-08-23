import Foundation

public enum CharacterWidth {
    

    public static func width(of character: Character) -> Int {

        if character.unicodeScalars.contains(where: { $0.value == 0x200D }) {

            return 2
        }
        

        var hasBase = false
        var baseWidth = 0
        
        for scalar in character.unicodeScalars {
            if !isCombiningScalar(scalar) {
                hasBase = true

                if isEmoji(scalar) {
                    baseWidth = max(baseWidth, 2)
                } else {

                    switch eastAsianWidth(scalar.value) {
                    case .wide, .fullwidth:
                        baseWidth = max(baseWidth, 2)
                    case .ambiguous:
                        baseWidth = max(baseWidth, isInCJKContext() ? 2 : 1)
                    default:
                        baseWidth = max(baseWidth, 1)
                    }
                }
            }
        }
        

        if hasBase {
            return baseWidth
        }
        

        return 0
    }
    

    public static func cellWidth(of string: String) -> Int {
        string.reduce(0) { $0 + width(of: $1) }
    }
    

    public static func substring(
        _ string: String,
        fitting width: Int
    ) -> (String, remainingWidth: Int) {
        var currentWidth = 0
        var result = ""
        
        for char in string {
            let charWidth = self.width(of: char)
            if currentWidth + charWidth > width {
                break
            }
            result.append(char)
            currentWidth += charWidth
        }
        
        return (result, width - currentWidth)
    }
    

    public static func cursorPosition(
        after string: String,
        startingAt startColumn: Int = 0
    ) -> Int {
        startColumn + cellWidth(of: string)
    }
    

    
    private static func isCombiningScalar(_ scalar: UnicodeScalar) -> Bool {
        let value = scalar.value
        

        if (0x0300...0x036F).contains(value) {
            return true
        }

        if (0x1AB0...0x1AFF).contains(value) {
            return true
        }

        if (0xFE20...0xFE2F).contains(value) {
            return true
        }

        if value == 0x200C {
            return true
        }

        if (0xFE00...0xFE0F).contains(value) {
            return true
        }

        if (0xE0100...0xE01EF).contains(value) {
            return true
        }
        
        return false
    }
    
    private static func isEmoji(_ scalar: UnicodeScalar) -> Bool {

        if (0x1F300...0x1F9FF).contains(scalar.value) {
            return true
        }

        if (0x1F900...0x1F9FF).contains(scalar.value) {
            return true
        }

        if (0x1F600...0x1F64F).contains(scalar.value) {
            return true
        }

        if (0x1F680...0x1F6FF).contains(scalar.value) {
            return true
        }

        if (0x2600...0x26FF).contains(scalar.value) {
            return true
        }

        if (0x2700...0x27BF).contains(scalar.value) {
            return true
        }
        return false
    }
    
    private enum EastAsianWidth {
        case narrow
        case wide
        case fullwidth
        case halfwidth
        case ambiguous
        case neutral
    }
    
    private static func eastAsianWidth(_ value: UInt32) -> EastAsianWidth {

        if (0x4E00...0x9FFF).contains(value) {
            return .wide
        }

        if (0x3040...0x309F).contains(value) {
            return .wide
        }

        if (0x30A0...0x30FF).contains(value) {
            return .wide
        }

        if (0xFF01...0xFF60).contains(value) {
            return .fullwidth
        }

        if (0xFF61...0xFF9F).contains(value) {
            return .halfwidth
        }

        if (0xAC00...0xD7AF).contains(value) {
            return .wide
        }

        if (0x3000...0x303F).contains(value) {
            return .wide
        }

        if value < 0x80 {
            return .narrow
        }
        

        return .neutral
    }
    
    private static func isInCJKContext() -> Bool {

        if let lang = ProcessInfo.processInfo.environment["LANG"] {
            return lang.contains("ja") || lang.contains("zh") || lang.contains("ko")
        }
        

        let locale = Locale.current
        if #available(macOS 13, iOS 16, *) {
            if let languageCode = locale.language.languageCode?.identifier {
                return ["ja", "zh", "ko"].contains(languageCode)
            }
        } else {

            if let languageCode = locale.languageCode {
                return ["ja", "zh", "ko"].contains(languageCode)
            }
        }
        
        return false
    }
}

public extension String {

    var terminalWidth: Int {
        CharacterWidth.cellWidth(of: self)
    }
    

    func fitting(width: Int) -> String {
        CharacterWidth.substring(self, fitting: width).0
    }
    

    func padded(to width: Int, with character: Character = " ") -> String {
        let currentWidth = terminalWidth
        if currentWidth >= width {
            return self
        }
        
        let padChar = String(character)
        let padWidth = CharacterWidth.width(of: character)
        let neededWidth = width - currentWidth
        let padCount = neededWidth / padWidth
        
        return self + String(repeating: padChar, count: padCount)
    }
    

    func truncated(to width: Int, ellipsis: String = "...") -> String {
        let currentWidth = terminalWidth
        if currentWidth <= width {
            return self
        }
        
        let ellipsisWidth = ellipsis.terminalWidth
        if width <= ellipsisWidth {
            return ellipsis.fitting(width: width)
        }
        
        let targetWidth = width - ellipsisWidth
        let truncated = fitting(width: targetWidth)
        return truncated + ellipsis
    }
}