import Foundation

public actor TerminalRuntime {

    public static let shared = TerminalRuntime()
    

    private var renderers: [any Renderer] = []
    

    private var currentTree: Node?
    
    /// Previous tree for diffing
    private var previousTree: Node?
    
    /// Reconciler for efficient tree diffing
    private let reconciler = Reconciler()

    private let layoutEngine: LayoutEngine
    

    private let paintEngine: PaintEngine
    

    private var terminalWidth: Int = 80
    private var terminalHeight: Int = 24
    

    private var animationTasks: [Address: Task<Void, Never>] = [:]
    

    private var sessionOptions: SessionOptions = .default
    

    private var debug: Bool = false
    
    private init() {
        let capabilities = Capabilities.detect()
        let theme = Theme.default
        
        self.layoutEngine = LayoutEngine()
        self.paintEngine = PaintEngine(theme: theme, capabilities: capabilities)
        

        if capabilities.isTTY {
            Task {
                await self.addRenderer(ANSIRenderer())
            }
        }
    }
    

    public func addRenderer(_ renderer: any Renderer) {
        renderers.append(renderer)
    }
    

    public func clearRenderers() {
        renderers.removeAll()
    }
    

    public func resize(width: Int, height: Int) {
        terminalWidth = width
        terminalHeight = height
        

        if let tree = currentTree {
            Task {
                await rerender(tree)
            }
        }
    }
    

    public func commit(_ tree: Node, options: SessionOptions = .default) async {
        sessionOptions = options
        debug = options.debug
        
        // Perform reconciliation with previous tree
        let reconciliationResult = reconciler.reconcile(
            oldTree: previousTree,
            newTree: tree
        )
        
        if debug {
            print("[DEBUG] Reconciliation: \(reconciliationResult.summary)")
            #if DEBUG
            reconciler.printReconciliation(reconciliationResult)
            #endif
        }
        
        // Layout the new tree
        let layoutContext = LayoutContext(
            width: terminalWidth,
            height: terminalHeight,
            theme: options.theme
        )
        let layoutTree = layoutEngine.layout(tree, context: layoutContext)
        
        // Generate commands based on reconciliation
        let commands: [RenderCommand]
        if previousTree == nil || !reconciliationResult.hasChanges {
            // Full render for first frame or no changes
            commands = [.clear] + paintEngine.paint(layoutTree)
        } else {
            // Incremental update based on reconciliation
            commands = generateIncrementalCommands(
                reconciliation: reconciliationResult,
                layoutTree: layoutTree
            )
        }
        
        if debug {
            print("[DEBUG] Generated \(commands.count) render commands")
        }
        
        // Apply the commands
        await applyCommands(commands)
        
        // Update state for next reconciliation
        previousTree = tree
        currentTree = layoutTree
    }
    
    /// Generate incremental render commands based on reconciliation
    private func generateIncrementalCommands(
        reconciliation: Reconciler.ReconciliationResult,
        layoutTree: Node
    ) -> [RenderCommand] {
        var commands: [RenderCommand] = []
        
        // Process deletions first (bottom-up)
        for deletion in reconciliation.deletions {
            commands.append(.end(deletion.node.address))
        }
        
        // Process moves
        for move in reconciliation.moves {
            if case .move(let from, let to) = move.type {
                // For now, treat moves as delete + insert
                commands.append(.end(from))
                commands.append(.begin(to, move.node.kind, parent: move.node.parentAddress))
            }
        }
        
        // Process updates
        for update in reconciliation.updates {
            // Paint only the updated node
            let paintCommands = paintEngine.paint(update.node)
            commands.append(contentsOf: paintCommands)
        }
        
        // Process insertions (top-down)
        for insertion in reconciliation.insertions {
            commands.append(.begin(
                insertion.node.address,
                insertion.node.kind,
                parent: insertion.node.parentAddress
            ))
            let paintCommands = paintEngine.paint(insertion.node)
            commands.append(contentsOf: paintCommands)
        }
        
        return commands
    }
    

    public func capabilities() -> Capabilities {

        if let firstRenderer = renderers.first {
            return firstRenderer.capabilities()
        }
        return Capabilities.detect()
    }
    

    public func applyCommands(_ commands: [RenderCommand]) async {

        await withTaskGroup(of: Void.self) { group in
            for renderer in renderers {
                group.addTask {
                    do {
                        try await renderer.apply(commands)
                        try await renderer.flush()
                    } catch {

                        _ = error
                    }
                }
            }
        }
    }
    

    private func rerender(_ tree: Node) async {
        await commit(tree, options: sessionOptions)
    }
    

    public func startAnimation(
        for address: Address,
        duration: TimeInterval,
        fps: Int,
        update: @escaping @Sendable (Double) async -> [RenderCommand]
    ) {

        animationTasks[address]?.cancel()
        

        let task = Task {
            let frameInterval = 1.0 / Double(min(fps, sessionOptions.liveFPS))
            let totalFrames = Int(duration / frameInterval)
            
            for frame in 0..<totalFrames {
                guard !Task.isCancelled else { break }
                
                let progress = Double(frame) / Double(totalFrames)
                let commands = await update(progress)
                await applyCommands(commands)
                
                try? await Task.sleep(nanoseconds: UInt64(frameInterval * 1_000_000_000))
            }
            

            if !Task.isCancelled {
                let commands = await update(1.0)
                await applyCommands(commands)
            }
            

            _ = animationTasks.removeValue(forKey: address)
        }
        
        animationTasks[address] = task
    }
    

    public func stopAnimation(for address: Address) {
        animationTasks[address]?.cancel()
        animationTasks.removeValue(forKey: address)
    }
    

    public func stopAllAnimations() {
        for task in animationTasks.values {
            task.cancel()
        }
        animationTasks.removeAll()
    }
    

    public func reset() async {

        stopAllAnimations()
        

        await withTaskGroup(of: Void.self) { group in
            for renderer in renderers {
                group.addTask {
                    try? await renderer.reset()
                }
            }
        }
        

        currentTree = nil
    }
}