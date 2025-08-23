import Foundation

public struct BracketedPasteManager {

    public static let enableSequence = "\u{1b}[?2004h"
    

    public static let disableSequence = "\u{1b}[?2004l"
    

    public static let startSequence = "\u{1b}[200~"
    

    public static let endSequence = "\u{1b}[201~"
    

    public static func isPasteStart(_ bytes: [UInt8]) -> Bool {
        return bytes.starts(with: startSequence.utf8)
    }
    

    public static func isPasteEnd(_ bytes: [UInt8]) -> Bool {
        return bytes.starts(with: endSequence.utf8)
    }
    

    public static func extractPastedText(from bytes: [UInt8]) -> String? {
        let startBytes = Array(startSequence.utf8)
        let endBytes = Array(endSequence.utf8)
        

        guard let startIndex = findSequence(startBytes, in: bytes) else {
            return nil
        }
        
        let afterStart = startIndex + startBytes.count
        guard afterStart < bytes.count else { return nil }
        

        guard let endIndex = findSequence(endBytes, in: Array(bytes[afterStart...])) else {
            return nil
        }
        
        let actualEndIndex = afterStart + endIndex
        

        let contentBytes = Array(bytes[afterStart..<actualEndIndex])
        return String(bytes: contentBytes, encoding: .utf8)
    }
    

    private static func findSequence(_ sequence: [UInt8], in bytes: [UInt8]) -> Int? {
        guard bytes.count >= sequence.count else { return nil }
        
        for i in 0...(bytes.count - sequence.count) {
            if Array(bytes[i..<(i + sequence.count)]) == sequence {
                return i
            }
        }
        return nil
    }
    

    public static func sanitizePastedText(_ text: String) -> String {
        text.unicodeScalars.compactMap { scalar in

            if scalar.value >= 0x20 ||
               scalar.value == 0x09 ||
               scalar.value == 0x0A ||
               scalar.value == 0x0D {
                return Character(scalar)
            }
            return nil
        }.map(String.init).joined()
    }
}

public struct PasteEvent: Sendable {
    public let text: String
    public let timestamp: Date
    public let isSanitized: Bool
    
    public init(text: String, sanitized: Bool = false) {
        self.text = sanitized ? BracketedPasteManager.sanitizePastedText(text) : text
        self.timestamp = Date()
        self.isSanitized = sanitized
    }
}

public protocol PasteHandler: Sendable {
    func handlePaste(_ event: PasteEvent) async
}

public struct DefaultPasteHandler: PasteHandler {
    private let insertHandler: @Sendable (String) async -> Void
    
    public init(insertHandler: @escaping @Sendable (String) async -> Void) {
        self.insertHandler = insertHandler
    }
    
    public func handlePaste(_ event: PasteEvent) async {
        await insertHandler(event.text)
    }
}