import Foundation

public enum RenderCommand: Sendable, Equatable {

    case begin(NodeID, NodeKind, parent: NodeID?)
    

    case setText(NodeID, String)
    

    case frame(NodeID, FramePayload)
    

    case end(NodeID)
    

    case clear
    

    case moveCursor(row: Int, column: Int)
    

    case setForeground(ANSIColor?)
    

    case setBackground(ANSIColor?)
    

    case setStyle(TextStyle)
    

    case reset
    

    case write(String)
    

    case writeLine(String)
    

    case clearLine
    

    case clearToEndOfLine
    

    case saveCursor
    

    case restoreCursor
    

    case hideCursor
    

    case showCursor
    

    case flush
}

public struct FramePayload: Sendable, Equatable {

    public let frame: Int
    

    public let progress: Double
    

    
    public init(frame: Int, progress: Double) {
        self.frame = frame
        self.progress = progress
    }
}

public struct TextStyle: OptionSet, Sendable {
    public let rawValue: UInt8
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    public static let bold = TextStyle(rawValue: 1 << 0)
    public static let dim = TextStyle(rawValue: 1 << 1)
    public static let italic = TextStyle(rawValue: 1 << 2)
    public static let underline = TextStyle(rawValue: 1 << 3)
    public static let blink = TextStyle(rawValue: 1 << 4)
    public static let reverse = TextStyle(rawValue: 1 << 5)
    public static let hidden = TextStyle(rawValue: 1 << 6)
    public static let strikethrough = TextStyle(rawValue: 1 << 7)
    
    public static let none = TextStyle([])
    public static let all: TextStyle = [.bold, .dim, .italic, .underline, .blink, .reverse, .hidden, .strikethrough]
}

public struct RenderBatch: Sendable {
    public let commands: [RenderCommand]
    public let timestamp: Date
    public let sessionID: String?
    
    public init(commands: [RenderCommand], timestamp: Date = Date(), sessionID: String? = nil) {
        self.commands = commands
        self.timestamp = timestamp
        self.sessionID = sessionID
    }
}

public extension RenderCommand {

    var isVisual: Bool {
        switch self {
        case .begin, .setText, .frame, .end,
             .write, .writeLine, .clear, .clearLine, .clearToEndOfLine:
            return true
        case .moveCursor, .setForeground, .setBackground, .setStyle,
             .reset, .saveCursor, .restoreCursor, .hideCursor, .showCursor, .flush:
            return false
        }
    }
    

    var isStyleModifier: Bool {
        switch self {
        case .setForeground, .setBackground, .setStyle, .reset:
            return true
        default:
            return false
        }
    }
}