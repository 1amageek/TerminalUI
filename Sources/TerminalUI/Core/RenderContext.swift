import Foundation

public struct RenderContext: Sendable {
    /// Terminal width in columns
    public let terminalWidth: Int
    
    /// Terminal height in rows
    public let terminalHeight: Int
    
    /// Terminal capabilities (colors, unicode, etc.)
    public let capabilities: Capabilities
    
    /// Theme for styling
    public let theme: Theme
    
    /// Stack of parent addresses for hierarchy tracking
    private var parentStack: [Address] = []
    
    /// Current path components for address generation
    internal private(set) var currentPath: [String] = []
    
    /// Current animation frame
    public let frame: Int
    
    /// Session configuration options
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
    
    /// Generate an address for the current position in the tree
    public mutating func makeAddress(for type: String? = nil) -> Address {
        let pathString = currentPath.joined(separator: ".")
        let typeString = type ?? "node"
        let addressString = pathString.isEmpty ? typeString : "\(pathString).\(typeString)"
        return Address(addressString)
    }
    
    /// Push a component to the current path
    public mutating func pushPath(_ component: String) {
        currentPath.append(component)
    }
    
    /// Pop the last component from the current path
    public mutating func popPath() {
        _ = currentPath.popLast()
    }
    
    /// Get the current parent's address
    public var currentParent: Address? {
        parentStack.last
    }
    
    /// Push a parent address to the stack
    public mutating func pushParent(_ address: Address) {
        parentStack.append(address)
    }
    
    /// Pop the last parent address from the stack
    public mutating func popParent() {
        _ = parentStack.popLast()
    }
    

    public func with(
        terminalWidth: Int? = nil,
        terminalHeight: Int? = nil,
        capabilities: Capabilities? = nil,
        theme: Theme? = nil,
        frame: Int? = nil,
        options: SessionOptions? = nil
    ) -> RenderContext {
        var newContext = RenderContext(
            terminalWidth: terminalWidth ?? self.terminalWidth,
            terminalHeight: terminalHeight ?? self.terminalHeight,
            capabilities: capabilities ?? self.capabilities,
            theme: theme ?? self.theme,
            frame: frame ?? self.frame,
            options: options ?? self.options
        )
        
        // Preserve internal state
        newContext.parentStack = self.parentStack
        newContext.currentPath = self.currentPath
        
        return newContext
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

// Terminal size 取得のプラットフォーム分岐
#if os(macOS)
import Darwin

private let TIOCGWINSZ: UInt = 0x40087468
private struct winsize {
    var ws_row: UInt16 = 0
    var ws_col: UInt16 = 0
    var ws_xpixel: UInt16 = 0
    var ws_ypixel: UInt16 = 0
}
#elseif os(Linux)
import Glibc

private let TIOCGWINSZ: CUnsignedLong = 0x5413
private struct winsize {
    var ws_row: CUnsignedShort = 0
    var ws_col: CUnsignedShort = 0
    var ws_xpixel: CUnsignedShort = 0
    var ws_ypixel: CUnsignedShort = 0
}
#endif