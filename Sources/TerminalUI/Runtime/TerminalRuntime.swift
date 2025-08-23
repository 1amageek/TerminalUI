import Foundation

public actor TerminalRuntime {

    public static let shared = TerminalRuntime()
    

    private var renderers: [any Renderer] = []
    

    private var currentTree: Node?
    

    

    

    private let layoutEngine: LayoutEngine
    

    private let paintEngine: PaintEngine
    

    private var terminalWidth: Int = 80
    private var terminalHeight: Int = 24
    

    private var animationTasks: [NodeID: Task<Void, Never>] = [:]
    

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
        

        let layoutContext = LayoutContext(
            width: terminalWidth,
            height: terminalHeight,
            theme: options.theme
        )
        let layoutTree = layoutEngine.layout(tree, context: layoutContext)
        

        let commands: [RenderCommand] = [.clear] + paintEngine.paint(layoutTree)
        

        if debug {
            print("[DEBUG] Generated \(commands.count) render commands")
        }
        

        await applyCommands(commands)
        

        currentTree = layoutTree
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
        for nodeID: NodeID,
        duration: TimeInterval,
        fps: Int,
        update: @escaping @Sendable (Double) async -> [RenderCommand]
    ) {

        animationTasks[nodeID]?.cancel()
        

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
            

            _ = animationTasks.removeValue(forKey: nodeID)
        }
        
        animationTasks[nodeID] = task
    }
    

    public func stopAnimation(for nodeID: NodeID) {
        animationTasks[nodeID]?.cancel()
        animationTasks.removeValue(forKey: nodeID)
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