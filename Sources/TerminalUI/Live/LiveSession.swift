import Foundation
import Synchronization

/// Manages independent updates of multiple UI elements
/// Example: build task lists, parallel download statuses
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
        
        var commands: [RenderCommand] = []
        
        if let pos = elements[id]?.position {
            commands.append(.moveCursor(row: pos.y, column: pos.x))
        }
        
        if let previous = previousNode {
            let reconciliation = reconciler.reconcile(
                oldTree: previous,
                newTree: node
            )
            
            if reconciliation.hasChanges {
                let incrementalCommands = generateIncrementalCommands(
                    reconciliation: reconciliation,
                    newTree: node
                )
                commands.append(contentsOf: incrementalCommands)
            }
        } else {
            commands.append(.begin(address, node.kind, parent: nil))
            commands.append(contentsOf: paintEngine.paint(node))
        }
        
        if !commands.isEmpty {
            await runtime.applyCommands(commands)
        }
    }
    
    public func remove(_ id: String) async {
        guard let element = elements.removeValue(forKey: id) else { return }
        
        await runtime.applyCommands([.end(element.address)])
        
        if !elements.isEmpty {
            await redrawAll()
        }
    }
    
    public func redrawAll() async {
        var commands: [RenderCommand] = [.clear]
        
        let sortedElements = elements.values.sorted { a, b in
            guard let posA = a.position, let posB = b.position else { return false }
            if posA.y != posB.y {
                return posA.y < posB.y
            }
            return posA.x < posB.x
        }
        
        for element in sortedElements {
            if let node = element.lastNode, let position = element.position {
                commands.append(.moveCursor(row: position.y, column: position.x))
                commands.append(contentsOf: paintEngine.paint(node))
            }
        }
        
        await runtime.applyCommands(commands)
    }
    
    public func clear() async {
        elements.removeAll()
        await runtime.applyCommands([.clear])
    }
    
    public func getView(_ id: String) -> (any ConsoleView)? {
        elements[id]?.view
    }
    
    public func getPosition(_ id: String) -> Point? {
        elements[id]?.position
    }
    
    public func move(_ id: String, to position: Point) async {
        guard var element = elements[id] else { return }
        element.position = position
        elements[id] = element
        
        await redrawAll()
    }
    
    public func getAllIDs() -> [String] {
        Array(elements.keys)
    }
    
    public var count: Int {
        elements.count
    }
    
    // MARK: - Private Helpers
    
    /// Generate incremental commands based on diff
    private func generateIncrementalCommands(
        reconciliation: Reconciler.ReconciliationResult,
        newTree: Node
    ) -> [RenderCommand] {
        var commands: [RenderCommand] = []
        
        for deletion in reconciliation.deletions {
            commands.append(.end(deletion.node.address))
        }
        
        for move in reconciliation.moves {
            if case .move(let from, let to) = move.type {
                commands.append(.end(from))
                commands.append(.begin(to, move.node.kind, parent: move.node.parentAddress))
                commands.append(contentsOf: paintEngine.paint(move.node))
            }
        }
        
        for update in reconciliation.updates {
            commands.append(.clearLine)
            commands.append(contentsOf: paintEngine.paint(update.node))
        }
        
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