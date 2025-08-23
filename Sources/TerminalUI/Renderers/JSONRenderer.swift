import Foundation
import Synchronization

public final class JSONRenderer: Renderer {
    private let output: FileHandle
    private let encoder: JSONEncoder
    private let capabilitiesValue: Capabilities
    private let includeTimestamps: Bool
    private let prettyPrint: Bool
    

    private struct NodeState {
        var nodeTree: [String: Any] = [:]
        var nodeStack: [String] = []
    }
    private let nodeState: Mutex<NodeState>
    
    public init(
        output: FileHandle = .standardOutput,
        capabilities: Capabilities? = nil,
        includeTimestamps: Bool = true,
        prettyPrint: Bool = false
    ) {
        self.output = output
        self.capabilitiesValue = capabilities ?? Capabilities(
            trueColor: true,
            xterm256: true,
            unicode: true,
            width: 120,
            height: 40,
            isTTY: false
        )
        self.includeTimestamps = includeTimestamps
        self.prettyPrint = prettyPrint
        self.nodeState = Mutex(NodeState())
        
        self.encoder = JSONEncoder()
        if prettyPrint {
            self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        if #available(macOS 10.15, iOS 13.0, *) {
            self.encoder.outputFormatting.insert(.withoutEscapingSlashes)
        }
    }
    
    public func apply(_ commands: [RenderCommand]) async throws {
        var events: [[String: Any]] = []
        
        for command in commands {
            if let event = commandToJSON(command) {
                events.append(event)
            }
        }
        
        if !events.isEmpty {
            try await writeEvents(events)
        }
    }
    
    private func commandToJSON(_ command: RenderCommand) -> [String: Any]? {
        var event: [String: Any] = [:]
        
        if includeTimestamps {
            event["timestamp"] = ISO8601DateFormatter().string(from: Date())
        }
        
        switch command {
        case .begin(let id, let kind, let parent):
            event["type"] = "begin"
            event["nodeId"] = id.description
            event["nodeKind"] = kind.rawValue
            if let parent = parent {
                event["parentId"] = parent.description
            }
            nodeState.withLock { state in
                state.nodeStack.append(id.description)
            }
            
        case .setText(let id, let text):
            event["type"] = "setText"
            event["nodeId"] = id.description
            event["text"] = text
            
        case .frame(let id, let payload):
            event["type"] = "frame"
            event["nodeId"] = id.description
            event["frame"] = payload.frame
            event["progress"] = payload.progress
            
        case .end(let id):
            event["type"] = "end"
            event["nodeId"] = id.description
            nodeState.withLock { state in
                if let lastId = state.nodeStack.last, lastId == id.description {
                    state.nodeStack.removeLast()
                }
            }
            
        case .clear:
            event["type"] = "clear"
            nodeState.withLock { state in
                state.nodeTree.removeAll()
                state.nodeStack.removeAll()
            }
            
        case .write(let text):
            event["type"] = "write"
            event["text"] = text
            
        case .writeLine(let text):
            event["type"] = "writeLine"
            event["text"] = text
            
        case .setForeground(let color):
            event["type"] = "setForeground"
            if let color = color {
                event["color"] = colorToJSON(color)
            }
            
        case .setBackground(let color):
            event["type"] = "setBackground"
            if let color = color {
                event["color"] = colorToJSON(color)
            }
            
        case .setStyle(let style):
            event["type"] = "setStyle"
            event["styles"] = styleToJSON(style)
            
        case .reset:
            event["type"] = "reset"
            
        case .moveCursor(let row, let column):
            event["type"] = "moveCursor"
            event["row"] = row
            event["column"] = column
            
        case .flush:
            event["type"] = "flush"
            
        default:
            return nil
        }
        
        return event
    }
    private func colorToJSON(_ color: ANSIColor) -> [String: Any] {
        switch color {
        case .indexed(let index):
            return ["type": "indexed", "value": index]
        case .xterm256(let index):
            return ["type": "xterm256", "value": index]
        case .rgb(let r, let g, let b):
            return ["type": "rgb", "r": r, "g": g, "b": b]
        case .semantic(let semantic):
            return ["type": "semantic", "value": semantic.rawValue]
        case .none:
            return ["type": "none"]
        }
    }
    
    private func styleToJSON(_ style: TextStyle) -> [String] {
        var styles: [String] = []
        if style.contains(.bold) { styles.append("bold") }
        if style.contains(.dim) { styles.append("dim") }
        if style.contains(.italic) { styles.append("italic") }
        if style.contains(.underline) { styles.append("underline") }
        if style.contains(.blink) { styles.append("blink") }
        if style.contains(.reverse) { styles.append("reverse") }
        if style.contains(.hidden) { styles.append("hidden") }
        if style.contains(.strikethrough) { styles.append("strikethrough") }
        return styles
    }
    
    private func writeEvents(_ events: [[String: Any]]) async throws {
        let nodeCount = nodeState.withLock { state in
            state.nodeStack.count
        }
        
        let jsonObject: [String: Any] = [
            "events": events,
            "nodeCount": nodeCount
        ]
        
        let data = try JSONSerialization.data(withJSONObject: jsonObject, options: prettyPrint ? [.prettyPrinted, .sortedKeys] : [])
        output.write(data)
        output.write("\n".data(using: .utf8)!)
    }
    
    public func flush() async throws {
        output.synchronizeFile()
    }
    
    public func reset() async throws {
        nodeState.withLock { state in
            state.nodeTree.removeAll()
            state.nodeStack.removeAll()
        }
        
        let resetEvent: [String: Any] = [
            "type": "reset",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        try await writeEvents([resetEvent])
    }
    
    public func capabilities() -> Capabilities {
        capabilitiesValue
    }
}