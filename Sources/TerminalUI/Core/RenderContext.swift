import Foundation

public struct RenderContext: Sendable {

    public let terminalWidth: Int
    

    public let terminalHeight: Int
    

    public let capabilities: Capabilities
    

    public let theme: Theme
    

    private var parentStack: [NodeID] = []
    

    private var nodeCounter: Int = 0
    

    private var currentPath: [String] = []
    

    public let frame: Int
    

    public let options: SessionOptions
    
    public init(
        terminalWidth: Int = 80,
        terminalHeight: Int = 24,
        capabilities: Capabilities = .default,
        theme: Theme = .default,
        frame: Int = 0,
        options: SessionOptions = .init()
    ) {
        self.terminalWidth = terminalWidth
        self.terminalHeight = terminalHeight
        self.capabilities = capabilities
        self.theme = theme
        self.frame = frame
        self.options = options
    }
    

    public mutating func makeNodeID(for type: String? = nil) -> NodeID {
        nodeCounter += 1
        let pathString = currentPath.joined(separator: ".")
        let typeString = type ?? "node"
        let id = "\(pathString).\(typeString).\(nodeCounter)"
        return NodeID(id)
    }
    

    public mutating func pushPath(_ component: String) {
        currentPath.append(component)
    }
    

    public mutating func popPath() {
        _ = currentPath.popLast()
    }
    

    public var currentParent: NodeID? {
        parentStack.last
    }
    

    public mutating func pushParent(_ id: NodeID) {
        parentStack.append(id)
    }
    

    public mutating func popParent() {
        _ = parentStack.popLast()
    }
    

    public func with(
        terminalWidth: Int? = nil,
        terminalHeight: Int? = nil,
        capabilities: Capabilities? = nil,
        theme: Theme? = nil,
        frame: Int? = nil
    ) -> RenderContext {
        var context = self
        if let width = terminalWidth {
            context = RenderContext(
                terminalWidth: width,
                terminalHeight: context.terminalHeight,
                capabilities: context.capabilities,
                theme: context.theme,
                frame: context.frame,
                options: context.options
            )
        }
        return context
    }
}

public struct Capabilities: Sendable {

    public let trueColor: Bool
    

    public let xterm256: Bool
    

    public let unicode: Bool
    

    public let width: Int
    

    public let height: Int
    

    public let mouseSupport: Bool
    

    public let kittyKeyboard: Bool
    

    public let sixelSupport: Bool
    

    public let kittyGraphics: Bool
    

    public let isCI: Bool
    

    public let isTTY: Bool
    
    public init(
        trueColor: Bool = false,
        xterm256: Bool = true,
        unicode: Bool = true,
        width: Int = 80,
        height: Int = 24,
        mouseSupport: Bool = false,
        kittyKeyboard: Bool = false,
        sixelSupport: Bool = false,
        kittyGraphics: Bool = false,
        isCI: Bool = false,
        isTTY: Bool = true
    ) {
        self.trueColor = trueColor
        self.xterm256 = xterm256
        self.unicode = unicode
        self.width = width
        self.height = height
        self.mouseSupport = mouseSupport
        self.kittyKeyboard = kittyKeyboard
        self.sixelSupport = sixelSupport
        self.kittyGraphics = kittyGraphics
        self.isCI = isCI
        self.isTTY = isTTY
    }
    

    public static let `default` = Capabilities()
    

    public static func detect() -> Capabilities {
        let env = ProcessInfo.processInfo.environment
        

        let trueColor = env["COLORTERM"] == "truecolor" || env["COLORTERM"] == "24bit"
        let term = env["TERM"] ?? ""
        let xterm256 = term.contains("256color") || trueColor
        

        let isCI = env["CI"] != nil || env["GITHUB_ACTIONS"] != nil
        

        let isTTY = isatty(STDOUT_FILENO) != 0
        

        var size = winsize()
        _ = ioctl(STDOUT_FILENO, TIOCGWINSZ, &size)
        let width = Int(size.ws_col) > 0 ? Int(size.ws_col) : 80
        let height = Int(size.ws_row) > 0 ? Int(size.ws_row) : 24
        

        let kittyKeyboard = env["TERM"] == "xterm-kitty"
        let sixelSupport = term.contains("sixel")
        let kittyGraphics = env["TERM"] == "xterm-kitty"
        
        return Capabilities(
            trueColor: trueColor,
            xterm256: xterm256,
            unicode: true,
            width: width,
            height: height,
            mouseSupport: !isCI && isTTY,
            kittyKeyboard: kittyKeyboard,
            sixelSupport: sixelSupport,
            kittyGraphics: kittyGraphics,
            isCI: isCI,
            isTTY: isTTY
        )
    }
}

#if os(macOS) || os(Linux)
import Darwin

private let TIOCGWINSZ: UInt = 0x40087468

private struct winsize {
    var ws_row: UInt16 = 0
    var ws_col: UInt16 = 0
    var ws_xpixel: UInt16 = 0
    var ws_ypixel: UInt16 = 0
}

#endif