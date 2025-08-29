import Foundation
import Synchronization

/// 複数のUI要素を独立して更新管理
/// 例: ビルドタスクリスト、並行ダウンロード状況など
public actor LiveSession {
    private let runtime: TerminalRuntime
    private let paintEngine: PaintEngine
    private let theme: Theme
    private let capabilities: Capabilities
    private let reconciler: Reconciler
    private var elements: [String: LiveElement] = [:]
    
    private struct LiveElement {
        let address: Address
        var lastNode: Node?
        var position: Point?
        var view: any ConsoleView
    }
    
    public init(
        runtime: TerminalRuntime = .shared,
        theme: Theme = .default,
        capabilities: Capabilities? = nil
    ) {
        self.runtime = runtime
        self.theme = theme
        self.capabilities = capabilities ?? Capabilities.detect()
        self.paintEngine = PaintEngine(theme: theme, capabilities: self.capabilities)
        self.reconciler = Reconciler()
    }
    
    /// 要素を追加/更新
    /// - Parameters:
    ///   - id: 要素の識別子（例: "task-1", "download-file.zip"）
    ///   - view: 表示するビュー
    ///   - position: 表示位置（省略時は自動配置）
    public func update<V: ConsoleView>(
        _ id: String,
        at position: Point? = nil,
        with view: V
    ) async {
        var context = RenderContext(
            terminalWidth: capabilities.width,
            terminalHeight: capabilities.height,
            capabilities: capabilities,
            theme: theme
        )
        
        let node = view._makeNode(context: &context)
        
        // 既存要素の更新か新規追加かを判定
        let previousNode: Node?
        let address: Address
        
        if let existing = elements[id] {
            previousNode = existing.lastNode
            address = existing.address
            elements[id] = LiveElement(
                address: address,
                lastNode: node,
                position: position ?? existing.position,
                view: view
            )
        } else {
            previousNode = nil
            address = Address("live.\(id)")
            let autoPosition = position ?? Point(x: 0, y: elements.count * 3)
            elements[id] = LiveElement(
                address: address,
                lastNode: node,
                position: autoPosition,
                view: view
            )
        }
        
        // コマンド生成
        var commands: [RenderCommand] = []
        
        // 位置移動
        if let pos = elements[id]?.position {
            commands.append(.moveCursor(row: pos.y, column: pos.x))
        }
        
        // 差分レンダリングまたは新規レンダリング
        if let previous = previousNode {
            // 差分レンダリング
            let reconciliation = reconciler.reconcile(
                oldTree: previous,
                newTree: node
            )
            
            if reconciliation.hasChanges {
                // 変更がある場合のみ更新
                let incrementalCommands = generateIncrementalCommands(
                    reconciliation: reconciliation,
                    newTree: node
                )
                commands.append(contentsOf: incrementalCommands)
            }
        } else {
            // 新規レンダリング
            commands.append(.begin(address, node.kind, parent: nil))
            commands.append(contentsOf: paintEngine.paint(node))
        }
        
        // コマンド適用
        if !commands.isEmpty {
            await runtime.applyCommands(commands)
        }
    }
    
    /// 要素を削除
    public func remove(_ id: String) async {
        guard let element = elements.removeValue(forKey: id) else { return }
        
        // 削除コマンドを発行
        await runtime.applyCommands([.end(element.address)])
        
        // 必要に応じて画面を再描画
        if !elements.isEmpty {
            await redrawAll()
        }
    }
    
    /// 全体を再描画
    public func redrawAll() async {
        var commands: [RenderCommand] = [.clear]
        
        // 全要素を位置順にソート
        let sortedElements = elements.values.sorted { a, b in
            guard let posA = a.position, let posB = b.position else { return false }
            if posA.y != posB.y {
                return posA.y < posB.y
            }
            return posA.x < posB.x
        }
        
        // 各要素を再描画
        for element in sortedElements {
            if let node = element.lastNode, let position = element.position {
                commands.append(.moveCursor(row: position.y, column: position.x))
                commands.append(contentsOf: paintEngine.paint(node))
            }
        }
        
        await runtime.applyCommands(commands)
    }
    
    /// 全要素をクリア
    public func clear() async {
        elements.removeAll()
        await runtime.applyCommands([.clear])
    }
    
    /// 指定IDの要素を取得
    public func getView(_ id: String) -> (any ConsoleView)? {
        elements[id]?.view
    }
    
    /// 指定IDの要素の位置を取得
    public func getPosition(_ id: String) -> Point? {
        elements[id]?.position
    }
    
    /// 要素の位置を変更
    public func move(_ id: String, to position: Point) async {
        guard var element = elements[id] else { return }
        element.position = position
        elements[id] = element
        
        // 再描画
        await redrawAll()
    }
    
    /// 全要素のIDを取得
    public func getAllIDs() -> [String] {
        Array(elements.keys)
    }
    
    /// 要素数を取得
    public var count: Int {
        elements.count
    }
    
    // MARK: - Private Helpers
    
    /// 差分に基づくインクリメンタルコマンドを生成
    private func generateIncrementalCommands(
        reconciliation: Reconciler.ReconciliationResult,
        newTree: Node
    ) -> [RenderCommand] {
        var commands: [RenderCommand] = []
        
        // 削除処理
        for deletion in reconciliation.deletions {
            commands.append(.end(deletion.node.address))
        }
        
        // 移動処理
        for move in reconciliation.moves {
            if case .move(let from, let to) = move.type {
                commands.append(.end(from))
                commands.append(.begin(to, move.node.kind, parent: move.node.parentAddress))
                commands.append(contentsOf: paintEngine.paint(move.node))
            }
        }
        
        // 更新処理
        for update in reconciliation.updates {
            // 行をクリアしてから再描画
            commands.append(.clearLine)
            commands.append(contentsOf: paintEngine.paint(update.node))
        }
        
        // 挿入処理
        for insertion in reconciliation.insertions {
            commands.append(.begin(
                insertion.node.address,
                insertion.node.kind,
                parent: insertion.node.parentAddress
            ))
            commands.append(contentsOf: paintEngine.paint(insertion.node))
        }
        
        return commands
    }
}