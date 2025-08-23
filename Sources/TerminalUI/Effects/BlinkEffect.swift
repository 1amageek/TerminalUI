import Foundation

public struct BlinkEffect: ConsoleView {
    private let content: AnyConsoleView
    private let interval: TimeInterval
    private let dutyCycle: Double
    private let isActive: Bool
    
    public init<Content: ConsoleView>(
        interval: TimeInterval = 1.0,
        dutyCycle: Double = 0.5,
        isActive: Bool = true,
        @ConsoleBuilder content: () -> Content
    ) {
        self.content = AnyConsoleView(content())
        self.interval = interval
        self.dutyCycle = max(0.0, min(1.0, dutyCycle))
        self.isActive = isActive
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {
        var node = content._makeNode(context: &context)
        
        if isActive {
            let blinkKey = PropertyContainer.Key<Bool>("blink")
            let blinkIntervalKey = PropertyContainer.Key<TimeInterval>("blinkInterval")
            let blinkDutyCycleKey = PropertyContainer.Key<Double>("blinkDutyCycle")
            let blinkFrameKey = PropertyContainer.Key<Int>("blinkFrame")
            
            node = node.with(properties: node.properties
                .with(blinkKey, value: true)
                .with(blinkIntervalKey, value: interval)
                .with(blinkDutyCycleKey, value: dutyCycle)
                .with(blinkFrameKey, value: context.frame)
            )
        }
        
        return node
    }
    
    public var body: Never {
        fatalError("BlinkEffect is a modifier")
    }
}

public extension ConsoleView {
    func blink(
        interval: TimeInterval = 1.0,
        dutyCycle: Double = 0.5,
        isActive: Bool = true
    ) -> some ConsoleView {
        BlinkEffect(
            interval: interval,
            dutyCycle: dutyCycle,
            isActive: isActive
        ) {
            self
        }
    }
}

public struct BlinkAnimator {
    private let scheduler = AnimationScheduler.shared
    private let runtime = TerminalRuntime.shared
    

    public func startBlink(
        nodeID: NodeID,
        interval: TimeInterval,
        dutyCycle: Double
    ) async {
        let animationID = AnimationScheduler.AnimationID("blink-\(nodeID.value)")
        

        let onDuration = interval * dutyCycle
        let offDuration = interval * (1.0 - dutyCycle)
        

        await animateCycle(
            animationID: animationID,
            nodeID: nodeID,
            onDuration: onDuration,
            offDuration: offDuration
        )
    }
    
    private func animateCycle(
        animationID: AnimationScheduler.AnimationID,
        nodeID: NodeID,
        onDuration: TimeInterval,
        offDuration: TimeInterval
    ) async {
        while await scheduler.isAnimating(animationID) {

            await runtime.applyCommands([.showCursor])
            try? await Task.sleep(nanoseconds: UInt64(onDuration * 1_000_000_000))
            

            await runtime.applyCommands([.hideCursor])
            try? await Task.sleep(nanoseconds: UInt64(offDuration * 1_000_000_000))
        }
    }
    

    public func stopBlink(nodeID: NodeID) async {
        let animationID = AnimationScheduler.AnimationID("blink-\(nodeID.value)")
        await scheduler.cancelAnimation(animationID)
        

        await runtime.applyCommands([.showCursor])
    }
}

public enum BlinkStyle {
    case slow
    case normal
    case fast
    case alert
    case subtle
    
    public var interval: TimeInterval {
        switch self {
        case .slow:
            return 2.0
        case .normal:
            return 1.0
        case .fast:
            return 0.5
        case .alert:
            return 0.3
        case .subtle:
            return 1.5
        }
    }
    
    public var dutyCycle: Double {
        switch self {
        case .slow, .normal:
            return 0.5
        case .fast:
            return 0.6
        case .alert:
            return 0.7
        case .subtle:
            return 0.3
        }
    }
}

public struct FadeBlinkEffect: ConsoleView {
    private let content: AnyConsoleView
    private let duration: TimeInterval
    private let minOpacity: Double
    private let maxOpacity: Double
    private let isActive: Bool
    
    public init<Content: ConsoleView>(
        duration: TimeInterval = 1.0,
        minOpacity: Double = 0.3,
        maxOpacity: Double = 1.0,
        isActive: Bool = true,
        @ConsoleBuilder content: () -> Content
    ) {
        self.content = AnyConsoleView(content())
        self.duration = duration
        self.minOpacity = max(0.0, min(1.0, minOpacity))
        self.maxOpacity = max(0.0, min(1.0, maxOpacity))
        self.isActive = isActive
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {
        var node = content._makeNode(context: &context)
        
        if isActive {
            let fadeBlinkKey = PropertyContainer.Key<Bool>("fadeBlink")
            let fadeBlinkDurationKey = PropertyContainer.Key<TimeInterval>("fadeBlinkDuration")
            let fadeBlinkMinOpacityKey = PropertyContainer.Key<Double>("fadeBlinkMinOpacity")
            let fadeBlinkMaxOpacityKey = PropertyContainer.Key<Double>("fadeBlinkMaxOpacity")
            
            node = node.with(properties: node.properties
                .with(fadeBlinkKey, value: true)
                .with(fadeBlinkDurationKey, value: duration)
                .with(fadeBlinkMinOpacityKey, value: minOpacity)
                .with(fadeBlinkMaxOpacityKey, value: maxOpacity)
            )
        }
        
        return node
    }
    
    public var body: Never {
        fatalError("FadeBlinkEffect is a modifier")
    }
}

public struct FadeBlinkAnimator: Sendable {
    private let scheduler = AnimationScheduler.shared
    private let runtime = TerminalRuntime.shared
    

    public func startFadeBlink(
        nodeID: NodeID,
        duration: TimeInterval,
        minOpacity: Double,
        maxOpacity: Double
    ) async {
        let animationID = AnimationScheduler.AnimationID("fade-blink-\(nodeID.value)")
        
        await scheduler.animate(
            id: animationID,
            duration: duration,
            update: { progress in

                let opacity = calculateOpacity(
                    progress: progress,
                    min: minOpacity,
                    max: maxOpacity
                )
                
                let commands = generateOpacityCommands(
                    nodeID: nodeID,
                    opacity: opacity
                )
                
                await runtime.applyCommands(commands)
            }
        )
    }
    
    private func calculateOpacity(progress: Double, min: Double, max: Double) -> Double {

        let sine = sin(progress * 2 * .pi)
        let normalized = (sine + 1.0) / 2.0
        return min + (max - min) * normalized
    }
    
    private func generateOpacityCommands(nodeID: NodeID, opacity: Double) -> [RenderCommand] {

        if opacity < 0.5 {
            return [.setStyle(.dim)]
        } else {
            return [.setStyle(.none)]
        }
    }
}