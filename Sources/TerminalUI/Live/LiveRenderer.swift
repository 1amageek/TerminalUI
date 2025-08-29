import Foundation

/// リアルタイムUI更新のための公開レンダラー
/// 長時間実行プロセスやストリーミングデータの表示に使用
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
    
    /// ConsoleViewを即座にレンダリング
    /// - Parameter view: 表示するビュー
    /// - Note: ストリーミングテキストやプログレス表示の更新に使用
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
    
    /// 画面をクリア
    public func clear() async {
        await runtime.applyCommands([.clear])
    }
    
    /// カーソル位置にテキストを上書き（ちらつき防止）
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
    
    /// 画面全体をリセット
    public func reset() async {
        await runtime.reset()
    }
    
    /// 現在のカーソル位置を保存
    public func saveCursor() async {
        await runtime.applyCommands([.saveCursor])
    }
    
    /// 保存したカーソル位置を復元
    public func restoreCursor() async {
        await runtime.applyCommands([.restoreCursor])
    }
    
    /// カーソルを非表示にする
    public func hideCursor() async {
        await runtime.applyCommands([.hideCursor])
    }
    
    /// カーソルを表示する
    public func showCursor() async {
        await runtime.applyCommands([.showCursor])
    }
    
    /// 現在の行をクリア
    public func clearLine() async {
        await runtime.applyCommands([.clearLine])
    }
    
    /// 行末までクリア
    public func clearToEndOfLine() async {
        await runtime.applyCommands([.clearToEndOfLine])
    }
    
    /// カーソルを移動
    public func moveCursor(to position: Point) async {
        await runtime.applyCommands([.moveCursor(row: position.y, column: position.x)])
    }
    
    /// フラッシュ（バッファ内容を強制出力）
    public func flush() async {
        await runtime.applyCommands([.flush])
    }
}