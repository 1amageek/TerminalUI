import Foundation

public struct Code: ConsoleView {
    private let content: String
    private let language: String?
    private let showLineNumbers: Bool
    private let lineNumberColor: ANSIColor
    private let backgroundColor: ANSIColor?
    private let highlightedLines: [Int]
    
    public init(
        _ content: String,
        language: String? = nil,
        showLineNumbers: Bool = false,
        lineNumberColor: ANSIColor = .semantic(.muted),
        backgroundColor: ANSIColor? = nil,
        highlightedLines: [Int] = []
    ) {
        self.content = content
        self.language = language
        self.showLineNumbers = showLineNumbers
        self.lineNumberColor = lineNumberColor
        self.backgroundColor = backgroundColor
        self.highlightedLines = highlightedLines
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        
        let properties = PropertyContainer()
            .with(.lines, value: lines)
            .with(.language, value: language ?? "")
            .with(.showLineNumbers, value: showLineNumbers)
            .with(.backgroundColor, value: backgroundColor?.toHex() ?? "")
        
        return Node(
            address: context.makeAddress(for: "code"),
            logicalID: nil,
            kind: .code,
            properties: properties,
            parentAddress: context.currentParent
        )
    }
}

public struct CodeRenderer {
    private let theme: Theme
    
    public init(theme: Theme = .default) {
        self.theme = theme
    }
    
    public func render(_ node: Node, at position: Point, width: Int) -> [RenderCommand] {
        var commands: [RenderCommand] = []
        
        guard let lines: [String] = node.properties[.lines] else {
            return commands
        }
        
        let language = node.properties[.language] ?? ""
        let showLineNumbers = node.properties[.showLineNumbers] ?? false
        let highlightLines: Set<Int> = []
        
        var currentY = position.y
        

        if !language.isEmpty {
            commands.append(.moveCursor(row: currentY, column: position.x))
            commands.append(.setForeground(.semantic(.muted)))
            commands.append(.write("// \(language)"))
            commands.append(.reset)
            currentY += 1
        }
        

        let lineNumberWidth = showLineNumbers ? String(lines.count).count + 2 : 0
        

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            
            commands.append(.moveCursor(row: currentY, column: position.x))
            

            if let bgColorHex: String = node.properties[.backgroundColor], !bgColorHex.isEmpty {
                if let bgColor = ANSIColor.fromHex(bgColorHex) {
                    commands.append(.setBackground(bgColor))
                }
            }
            

            if highlightLines.contains(lineNumber) {
                commands.append(.setBackground(.semantic(.warning)))
                commands.append(.setForeground(.rgb(0, 0, 0)))
            }
            

            if showLineNumbers {
                commands.append(.setForeground(.semantic(.muted)))
                let paddedLineNum = String(lineNumber).padding(toLength: lineNumberWidth - 2, withPad: " ", startingAt: 0)
                commands.append(.write("\(paddedLineNum)│ "))
                commands.append(.reset)
                

                if highlightLines.contains(lineNumber) {
                    commands.append(.setBackground(.semantic(.warning)))
                    commands.append(.setForeground(.rgb(0, 0, 0)))
                }
            }
            

            commands.append(.write(line))
            

            let contentWidth = (showLineNumbers ? lineNumberWidth : 0) + line.terminalWidth
            let remaining = max(0, width - contentWidth)
            if remaining > 0 {
                commands.append(.write(String(repeating: " ", count: remaining)))
            }
            
            commands.append(.reset)
            currentY += 1
        }
        
        return commands
    }
}

public extension Code {

    static func swift(_ content: String, showLineNumbers: Bool = true) -> Code {
        Code(content, language: "Swift", showLineNumbers: showLineNumbers)
    }
    

    static func javascript(_ content: String, showLineNumbers: Bool = true) -> Code {
        Code(content, language: "JavaScript", showLineNumbers: showLineNumbers)
    }
    

    static func python(_ content: String, showLineNumbers: Bool = true) -> Code {
        Code(content, language: "Python", showLineNumbers: showLineNumbers)
    }
    

    static func json(_ content: String) -> Code {
        Code(content, language: "JSON", showLineNumbers: false)
    }
    

    static func shell(_ content: String) -> Code {
        Code(content, language: "Shell", showLineNumbers: false)
    }
    
    public var body: Never {
        fatalError("Code is a primitive view")
    }
}