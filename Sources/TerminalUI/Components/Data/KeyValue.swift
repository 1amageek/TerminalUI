import Foundation

public struct KeyValue: ConsoleView {
    private let pairs: [(key: String, value: String)]
    private let separator: String
    private let alignment: KeyValueAlignment
    private let keyColor: ANSIColor?
    private let valueColor: ANSIColor?
    private let compact: Bool
    
    public enum KeyValueAlignment: Sendable {
        case inline
        case aligned(keyWidth: Int)
        case vertical
    }
    
    public init(
        pairs: [(key: String, value: String)],
        separator: String = ":",
        alignment: KeyValueAlignment = .inline,
        keyColor: ANSIColor? = nil,
        valueColor: ANSIColor? = nil,
        compact: Bool = false
    ) {
        self.pairs = pairs
        self.separator = separator
        self.alignment = alignment
        self.keyColor = keyColor
        self.valueColor = valueColor
        self.compact = compact
    }
    
    public init(
        _ dictionary: [String: String],
        separator: String = ":",
        alignment: KeyValueAlignment = .inline,
        keyColor: ANSIColor? = nil,
        valueColor: ANSIColor? = nil,
        compact: Bool = false
    ) {
        self.pairs = dictionary.map { ($0.key, $0.value) }.sorted { $0.key < $1.key }
        self.separator = separator
        self.alignment = alignment
        self.keyColor = keyColor
        self.valueColor = valueColor
        self.compact = compact
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {
        let keyWidth = switch alignment {
        case .aligned(let width):
            width
        default:
            pairs.map { $0.key.count }.max() ?? 0
        }
        
        let kvPairs = pairs.map { KeyValuePair(key: $0.key, value: $0.value) }
        
        let properties = PropertyContainer()
            .with(.pairs, value: kvPairs)
            .with(.unit, value: separator)
            .with(.kind, value: alignmentString(alignment))
            .with(.width, value: keyWidth)
            .with(.foreground, value: keyColor?.toHex() ?? "")
            .with(.background, value: valueColor?.toHex() ?? "")
            .with(.compact, value: compact)
        
        return Node(id: context.makeNodeID(), kind: .keyvalue, properties: properties)
    }
    
    private func alignmentString(_ alignment: KeyValueAlignment) -> String {
        switch alignment {
        case .inline: return "inline"
        case .aligned: return "aligned"
        case .vertical: return "vertical"
        }
    }
}

public struct KeyValueRenderer {
    private let theme: Theme
    
    public init(theme: Theme = .default) {
        self.theme = theme
    }
    
    public func render(_ node: Node, at position: Point, width: Int) -> [RenderCommand] {
        var commands: [RenderCommand] = []
        
        guard let pairs: [KeyValuePair] = node.properties[.pairs] else {
            return commands
        }
        
        let separator = node.properties[.unit] ?? ":"
        let alignment = node.properties[.kind] ?? "inline"
        let keyWidth = node.properties[.width] ?? 0
        let compact = node.properties[.compact] ?? false
        
        var currentY = position.y
        
        for (index, pair) in pairs.enumerated() {
            let key = pair.key
            let value = pair.value
            
            commands.append(.moveCursor(row: currentY, column: position.x))
            

            if let keyColorHex: String = node.properties[.foreground], !keyColorHex.isEmpty {
                if let color = ANSIColor.fromHex(keyColorHex) {
                    commands.append(.setForeground(color))
                }
            } else {
                commands.append(.setForeground(.semantic(.muted)))
            }
            

            switch alignment {
            case "vertical":

                commands.append(.write(key))
                commands.append(.write(separator))
                commands.append(.reset)
                currentY += 1
                

                commands.append(.moveCursor(row: currentY, column: position.x + 2))
                if let valueColorHex: String = node.properties[.background], !valueColorHex.isEmpty {
                    if let color = ANSIColor.fromHex(valueColorHex) {
                        commands.append(.setForeground(color))
                    }
                }
                commands.append(.write(value))
                
            case "aligned":

                let paddedKey = key.padding(toLength: keyWidth, withPad: " ", startingAt: 0)
                commands.append(.write(paddedKey))
                commands.append(.write(separator))
                commands.append(.write(" "))
                commands.append(.reset)
                
                if let valueColorHex: String = node.properties[.background], !valueColorHex.isEmpty {
                    if let color = ANSIColor.fromHex(valueColorHex) {
                        commands.append(.setForeground(color))
                    }
                }
                commands.append(.write(value))
                
            default:
                commands.append(.write(key))
                commands.append(.write(separator))
                commands.append(.write(" "))
                commands.append(.reset)
                
                if let valueColorHex: String = node.properties[.background], !valueColorHex.isEmpty {
                    if let color = ANSIColor.fromHex(valueColorHex) {
                        commands.append(.setForeground(color))
                    }
                }
                commands.append(.write(value))
            }
            
            commands.append(.reset)
            currentY += 1
            

            if !compact && index < pairs.count - 1 {
                currentY += 1
            }
        }
        
        return commands
    }
}

extension ANSIColor {
    func toHex() -> String {
        switch self {
        case .rgb(let r, let g, let b):
            return String(format: "#%02X%02X%02X", r, g, b)
        default:
            return ""
        }
    }
    
    static func fromHex(_ hex: String) -> ANSIColor? {
        var hexColor = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexColor.hasPrefix("#") {
            hexColor.removeFirst()
        }
        
        guard hexColor.count == 6,
              let rgb = Int(hexColor, radix: 16) else {
            return nil
        }
        
        let r = (rgb >> 16) & 0xFF
        let g = (rgb >> 8) & 0xFF
        let b = rgb & 0xFF
        
        return .rgb(UInt8(r), UInt8(g), UInt8(b))
    }
}