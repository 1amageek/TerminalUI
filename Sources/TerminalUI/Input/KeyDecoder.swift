import Foundation

public enum KeyEvent: Sendable, Equatable {
    case character(Character)
    case control(ControlKey)
    case ime(IMEEvent)
    case paste(String)
    case unknown([UInt8])
    
    public indirect enum ControlKey: Sendable, Equatable {
        case left, right, up, down
        case home, end
        case backspace, delete
        case enter, tab, escape
        case pageUp, pageDown
        case insert
        case f(Int)
        case character(Character)
        case withModifier(ControlKey, Modifier)
    }
    
    public struct Modifier: OptionSet, Sendable {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let shift = Modifier(rawValue: 1 << 0)
        public static let alt = Modifier(rawValue: 1 << 1)
        public static let ctrl = Modifier(rawValue: 1 << 2)
        public static let meta = Modifier(rawValue: 1 << 3)
    }
    
    public enum IMEEvent: Sendable, Equatable {
        case compositionStart
        case compositionUpdate(String)
        case compositionCommit(String)
        case compositionCancel
    }
}

public struct KeyDecoder {
    private var buffer: [UInt8] = []
    private var pasteBuffer: [UInt8] = []
    private var inPasteMode = false
    
    public init() {}
    

    public mutating func decode(_ bytes: [UInt8]) -> [KeyEvent] {
        buffer.append(contentsOf: bytes)
        var events: [KeyEvent] = []
        
        while !buffer.isEmpty {
            if let event = decodeNext() {
                events.append(event)
            } else {
                break
            }
        }
        
        return events
    }
    

    private mutating func decodeNext() -> KeyEvent? {
        guard !buffer.isEmpty else { return nil }
        

        if checkBracketedPaste() {
            return nil
        }
        

        if inPasteMode {
            if let pasteEnd = findSequence([0x1b, 0x5b, 0x32, 0x30, 0x31, 0x7e]) {
                let pasteData = Array(buffer[0..<pasteEnd])
                buffer.removeFirst(pasteEnd + 6)
                inPasteMode = false
                
                if let text = String(bytes: pasteData, encoding: .utf8) {
                    return .paste(text)
                }
                return nil
            }

            return nil
        }
        

        if buffer[0] == 0x1b {
            return decodeEscapeSequence()
        }
        

        if let control = decodeControlCharacter(buffer[0]) {
            buffer.removeFirst()
            return control
        }
        

        if let (char, length) = decodeUTF8() {
            buffer.removeFirst(length)
            return .character(char)
        }
        

        let byte = buffer.removeFirst()
        return .unknown([byte])
    }
    

    private mutating func checkBracketedPaste() -> Bool {

        if buffer.starts(with: [0x1b, 0x5b, 0x32, 0x30, 0x30, 0x7e]) {
            buffer.removeFirst(6)
            inPasteMode = true
            pasteBuffer.removeAll()
            return true
        }
        return false
    }
    

    private func findSequence(_ sequence: [UInt8]) -> Int? {
        guard buffer.count >= sequence.count else { return nil }
        
        for i in 0...(buffer.count - sequence.count) {
            if Array(buffer[i..<(i + sequence.count)]) == sequence {
                return i
            }
        }
        return nil
    }
    

    private mutating func decodeEscapeSequence() -> KeyEvent? {
        guard buffer.count >= 2 else { return nil }
        

        if buffer.count == 1 || 
           (buffer.count >= 2 && !isEscapeSequenceContinuation(buffer[1])) {
            buffer.removeFirst()
            return .control(.escape)
        }
        

        if buffer[1] == 0x5b {
            return decodeCSISequence()
        }
        

        if buffer[1] == 0x4f {
            return decodeSS3Sequence()
        }
        

        if buffer.count >= 2 {
            buffer.removeFirst()
            if let (char, length) = decodeUTF8() {
                buffer.removeFirst(length)

                if let ascii = char.asciiValue {
                    if let control = decodeControlCharacter(ascii) {
                        if case .control(let key) = control {
                            return .control(.withModifier(key, .alt))
                        }
                    }
                }

                return .control(.withModifier(.enter, .alt))
            }
        }
        
        return nil
    }
    

    private func isEscapeSequenceContinuation(_ byte: UInt8) -> Bool {
        return byte == 0x5b || byte == 0x4f || (byte >= 0x40 && byte <= 0x7e)
    }
    

    private mutating func decodeCSISequence() -> KeyEvent? {
        guard buffer.count >= 3 else { return nil }
        

        var endIndex = 2
        while endIndex < buffer.count && endIndex < 20 {
            let byte = buffer[endIndex]
            if byte >= 0x40 && byte <= 0x7e {

                let sequence = Array(buffer[0...endIndex])
                buffer.removeFirst(endIndex + 1)
                return parseCSISequence(sequence)
            }
            endIndex += 1
        }
        

        return nil
    }
    

    private func parseCSISequence(_ seq: [UInt8]) -> KeyEvent? {
        guard seq.count >= 3 else { return nil }
        
        let terminator = seq.last!
        let params = parseCSIParams(Array(seq[2..<(seq.count - 1)]))
        
        switch terminator {
        case 0x41:
            return .control(modifiedKey(.up, params))
        case 0x42:
            return .control(modifiedKey(.down, params))
        case 0x43:
            return .control(modifiedKey(.right, params))
        case 0x44:
            return .control(modifiedKey(.left, params))
        case 0x48:
            return .control(modifiedKey(.home, params))
        case 0x46:
            return .control(modifiedKey(.end, params))
        case 0x7e:
            return parseSpecialKey(params)
        case 0x50:
            return .control(.f(1))
        case 0x51:
            return .control(.f(2))
        case 0x52:
            return .control(.f(3))
        case 0x53:
            return .control(.f(4))
        default:
            return .unknown(seq)
        }
    }
    

    private func parseCSIParams(_ bytes: [UInt8]) -> [Int] {
        guard !bytes.isEmpty else { return [] }
        
        let string = String(bytes: bytes, encoding: .ascii) ?? ""
        return string.split(separator: ";").compactMap { Int($0) }
    }
    

    private func modifiedKey(_ key: KeyEvent.ControlKey, _ params: [Int]) -> KeyEvent.ControlKey {
        guard params.count >= 2 else { return key }
        
        let modifierCode = params[1] - 1
        var modifiers = KeyEvent.Modifier()
        
        if modifierCode & 1 != 0 { modifiers.insert(.shift) }
        if modifierCode & 2 != 0 { modifiers.insert(.alt) }
        if modifierCode & 4 != 0 { modifiers.insert(.ctrl) }
        if modifierCode & 8 != 0 { modifiers.insert(.meta) }
        
        if modifiers.isEmpty {
            return key
        } else {
            return .withModifier(key, modifiers)
        }
    }
    

    private func parseSpecialKey(_ params: [Int]) -> KeyEvent? {
        guard let first = params.first else { return nil }
        
        switch first {
        case 1: return .control(.home)
        case 2: return .control(.insert)
        case 3: return .control(.delete)
        case 4: return .control(.end)
        case 5: return .control(.pageUp)
        case 6: return .control(.pageDown)
        case 11...15: return .control(.f(first - 10))
        case 17...21: return .control(.f(first - 11))
        case 23, 24: return .control(.f(first - 12))
        default: return nil
        }
    }
    

    private mutating func decodeSS3Sequence() -> KeyEvent? {
        guard buffer.count >= 3 else { return nil }
        
        let third = buffer[2]
        buffer.removeFirst(3)
        
        switch third {
        case 0x50: return .control(.f(1))
        case 0x51: return .control(.f(2))
        case 0x52: return .control(.f(3))
        case 0x53: return .control(.f(4))
        case 0x48: return .control(.home)
        case 0x46: return .control(.end)
        default: return .unknown([0x1b, 0x4f, third])
        }
    }
    

    private func decodeControlCharacter(_ byte: UInt8) -> KeyEvent? {
        switch byte {
        case 0x00: return .control(.withModifier(.character(" "), .ctrl))
        case 0x01...0x1a:
            let letter = Character(UnicodeScalar(byte + 0x60))
            return .control(.withModifier(.character(letter), .ctrl))
        case 0x08, 0x7f: return .control(.backspace)
        case 0x09: return .control(.tab)
        case 0x0a, 0x0d: return .control(.enter)
        case 0x1b: return .control(.escape)
        default: return nil
        }
    }
    

    private func decodeUTF8() -> (Character, Int)? {
        guard !buffer.isEmpty else { return nil }
        
        let byte = buffer[0]
        var length = 0
        

        if byte & 0x80 == 0 {
            length = 1
        } else if byte & 0xe0 == 0xc0 {
            length = 2
        } else if byte & 0xf0 == 0xe0 {
            length = 3
        } else if byte & 0xf8 == 0xf0 {
            length = 4
        } else {
            return nil
        }
        
        guard buffer.count >= length else { return nil }
        
        let bytes = Array(buffer[0..<length])
        guard let string = String(bytes: bytes, encoding: .utf8),
              let char = string.first else {
            return nil
        }
        
        return (char, length)
    }
}

private extension KeyEvent.ControlKey {
    static func fromCharacter(_ char: Character) -> KeyEvent.ControlKey {

        return .character(char)
    }
}