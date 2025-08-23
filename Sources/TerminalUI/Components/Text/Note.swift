import Foundation

public struct Note: ConsoleView {
    private let message: String
    private let kind: NoteKind
    
    public enum NoteKind: Sendable {
        case info
        case success
        case warning
        case error
        
        var color: ANSIColor {
            switch self {
            case .info: return .semantic(.info)
            case .success: return .semantic(.success)
            case .warning: return .semantic(.warning)
            case .error: return .semantic(.error)
            }
        }
        
        var icon: String {
            switch self {
            case .info: return "ℹ"
            case .success: return "✓"
            case .warning: return "⚠"
            case .error: return "✗"
            }
        }
    }
    
    public init(_ message: String, kind: NoteKind = .info) {
        self.message = message
        self.kind = kind
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {
        let id = context.makeNodeID(for: "note")
        
        let properties = PropertyContainer()
            .with(.text, value: message)
            .with(.foreground, value: String(describing: kind.color))
            .with(.icon, value: kind.icon)
            .with(.kind, value: String(describing: kind))
        
        return Node(
            id: id,
            kind: .note,
            properties: properties,
            parentID: context.currentParent
        )
    }
}