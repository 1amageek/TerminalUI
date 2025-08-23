import Foundation

public struct EditorState: Sendable {
    private var text: String
    private var caretIndex: String.Index
    private var displayOffset: Int
    private let maxLength: Int?
    

    public init(text: String = "", maxLength: Int? = nil) {
        self.text = text
        self.caretIndex = text.endIndex
        self.displayOffset = 0
        self.maxLength = maxLength
    }
    

    

    public var content: String {
        text
    }
    

    public var caretPosition: Int {
        text.distance(from: text.startIndex, to: caretIndex)
    }
    

    public var textBeforeCaret: String {
        String(text[..<caretIndex])
    }
    

    public var textAfterCaret: String {
        String(text[caretIndex...])
    }
    

    public var isAtBeginning: Bool {
        caretIndex == text.startIndex
    }
    

    public var isAtEnd: Bool {
        caretIndex == text.endIndex
    }
    

    

    public mutating func insert(_ string: String) {

        if let max = maxLength {
            let currentLength = text.count
            let insertLength = string.count
            if currentLength + insertLength > max {

                let available = max - currentLength
                if available <= 0 { return }
                let truncated = String(string.prefix(available))
                performInsert(truncated)
                return
            }
        }
        performInsert(string)
    }
    
    private mutating func performInsert(_ string: String) {
        text.insert(contentsOf: string, at: caretIndex)

        caretIndex = text.index(caretIndex, offsetBy: string.count)
    }
    

    public mutating func deleteBackward() {
        guard caretIndex > text.startIndex else { return }
        

        let prevIndex = text.index(before: caretIndex)
        text.removeSubrange(prevIndex..<caretIndex)
        caretIndex = prevIndex
    }
    

    public mutating func deleteForward() {
        guard caretIndex < text.endIndex else { return }
        

        let nextIndex = text.index(after: caretIndex)
        text.removeSubrange(caretIndex..<nextIndex)

    }
    

    public mutating func deleteWordBackward() {
        guard caretIndex > text.startIndex else { return }
        

        let wordStart = findWordBoundaryBackward(from: caretIndex)
        text.removeSubrange(wordStart..<caretIndex)
        caretIndex = wordStart
    }
    

    public mutating func deleteWordForward() {
        guard caretIndex < text.endIndex else { return }
        

        let wordEnd = findWordBoundaryForward(from: caretIndex)
        text.removeSubrange(caretIndex..<wordEnd)

    }
    

    public mutating func deleteLine() {
        text = ""
        caretIndex = text.startIndex
        displayOffset = 0
    }
    

    public mutating func deleteToEnd() {
        text.removeSubrange(caretIndex..<text.endIndex)
    }
    

    public mutating func deleteToBeginning() {
        text.removeSubrange(text.startIndex..<caretIndex)
        caretIndex = text.startIndex
        displayOffset = 0
    }
    

    

    public mutating func moveLeft() {
        guard caretIndex > text.startIndex else { return }
        caretIndex = text.index(before: caretIndex)
    }
    

    public mutating func moveRight() {
        guard caretIndex < text.endIndex else { return }
        caretIndex = text.index(after: caretIndex)
    }
    

    public mutating func moveWordLeft() {
        caretIndex = findWordBoundaryBackward(from: caretIndex)
    }
    

    public mutating func moveWordRight() {
        caretIndex = findWordBoundaryForward(from: caretIndex)
    }
    

    public mutating func moveToBeginning() {
        caretIndex = text.startIndex
        displayOffset = 0
    }
    

    public mutating func moveToEnd() {
        caretIndex = text.endIndex
    }
    

    public mutating func moveTo(position: Int) {
        let clampedPosition = max(0, min(position, text.count))
        caretIndex = text.index(text.startIndex, offsetBy: clampedPosition)
    }
    

    

    public mutating func visibleText(width: Int) -> String {
        guard width > 0 else { return "" }
        

        let beforeCaretWidth = CharacterWidth.cellWidth(of: textBeforeCaret)
        

        if beforeCaretWidth < displayOffset {

            displayOffset = beforeCaretWidth
        } else if beforeCaretWidth >= displayOffset + width {

            displayOffset = beforeCaretWidth - width + 1
        }
        

        var currentWidth = 0
        var visibleStart = text.startIndex
        var visibleEnd = text.startIndex
        

        for (index, char) in text.enumerated() {
            let charWidth = CharacterWidth.width(of: char)
            if currentWidth >= displayOffset {
                visibleStart = text.index(text.startIndex, offsetBy: index)
                break
            }
            currentWidth += charWidth
        }
        

        currentWidth = 0
        var index = visibleStart
        while index < text.endIndex && currentWidth < width {
            let char = text[index]
            let charWidth = CharacterWidth.width(of: char)
            if currentWidth + charWidth > width {
                break
            }
            currentWidth += charWidth
            index = text.index(after: index)
            visibleEnd = index
        }
        
        return String(text[visibleStart..<visibleEnd])
    }
    

    public func caretColumn(width: Int) -> Int {
        let beforeCaretWidth = CharacterWidth.cellWidth(of: textBeforeCaret)
        return beforeCaretWidth - displayOffset
    }
    

    public mutating func scrollToCaret(width: Int) {
        _ = visibleText(width: width)
    }
    

    

    public mutating func setText(_ newText: String) {

        if let max = maxLength {
            text = String(newText.prefix(max))
        } else {
            text = newText
        }

        caretIndex = text.endIndex
        displayOffset = 0
    }
    

    public mutating func clear() {
        text = ""
        caretIndex = text.startIndex
        displayOffset = 0
    }
    

    
    private func findWordBoundaryBackward(from index: String.Index) -> String.Index {
        var currentIndex = index
        

        while currentIndex > text.startIndex {
            let prevIndex = text.index(before: currentIndex)
            if !text[prevIndex].isWhitespace {
                break
            }
            currentIndex = prevIndex
        }
        

        while currentIndex > text.startIndex {
            let prevIndex = text.index(before: currentIndex)
            let char = text[prevIndex]
            if char.isWhitespace || char.isPunctuation {
                break
            }
            currentIndex = prevIndex
        }
        
        return currentIndex
    }
    
    private func findWordBoundaryForward(from index: String.Index) -> String.Index {
        var currentIndex = index
        

        while currentIndex < text.endIndex {
            let char = text[currentIndex]
            if char.isWhitespace || char.isPunctuation {
                break
            }
            currentIndex = text.index(after: currentIndex)
        }
        

        while currentIndex < text.endIndex {
            if !text[currentIndex].isWhitespace {
                break
            }
            currentIndex = text.index(after: currentIndex)
        }
        
        return currentIndex
    }
}

public extension EditorState {

    func validate(with validator: (String) -> ValidationResult) -> ValidationResult {
        validator(text)
    }
}

public enum ValidationResult: Sendable {
    case ok
    case warning(String)
    case error(String)
    
    public var isValid: Bool {
        switch self {
        case .ok, .warning:
            return true
        case .error:
            return false
        }
    }
}