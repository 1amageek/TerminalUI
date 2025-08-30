import Foundation

/// Public renderer for real-time UI updates
/// Used for long-running processes and streaming data
public struct LiveRenderer: Sendable {
    private let runtime: TerminalRuntime
    private let paintEngine: PaintEngine
    private let theme: Theme
    private let capabilities: Capabilities
    
    public init(
        runtime: TerminalRuntime = .shared,
        theme: Theme = .default,
        capabilities: Capabilities? = nil
    ) {
        self.runtime = runtime
        self.theme = theme
        self.capabilities = capabilities ?? Capabilities.detect()
        self.paintEngine = PaintEngine(theme: theme, capabilities: self.capabilities)
    }
    
    public func render<V: ConsoleView>(_ view: V) async {
        var context = RenderContext(
            terminalWidth: capabilities.width,
            terminalHeight: capabilities.height,
            capabilities: capabilities,
            theme: theme
        )
        let node = view._makeNode(context: &context)
        let commands = paintEngine.paint(node)
        await runtime.applyCommands(commands)
    }
    
    public func clear() async {
        await runtime.applyCommands([.clear])
    }
    
    /// Overwrite text at cursor position (prevents flickering)
    public func update<V: ConsoleView>(at position: Point, view: V) async {
        var commands: [RenderCommand] = []
        commands.append(.saveCursor)
        commands.append(.moveCursor(row: position.y, column: position.x))
        
        var context = RenderContext(
            terminalWidth: capabilities.width,
            terminalHeight: capabilities.height,
            capabilities: capabilities,
            theme: theme
        )
        let node = view._makeNode(context: &context)
        commands.append(contentsOf: paintEngine.paint(node))
        commands.append(.restoreCursor)
        
        await runtime.applyCommands(commands)
    }
    
    public func reset() async {
        await runtime.reset()
    }
    
    public func saveCursor() async {
        await runtime.applyCommands([.saveCursor])
    }
    
    public func restoreCursor() async {
        await runtime.applyCommands([.restoreCursor])
    }
    
    public func hideCursor() async {
        await runtime.applyCommands([.hideCursor])
    }
    
    public func showCursor() async {
        await runtime.applyCommands([.showCursor])
    }
    
    public func clearLine() async {
        await runtime.applyCommands([.clearLine])
    }
    
    public func clearToEndOfLine() async {
        await runtime.applyCommands([.clearToEndOfLine])
    }
    
    public func moveCursor(to position: Point) async {
        await runtime.applyCommands([.moveCursor(row: position.y, column: position.x)])
    }
    
    public func flush() async {
        await runtime.applyCommands([.flush])
    }
}