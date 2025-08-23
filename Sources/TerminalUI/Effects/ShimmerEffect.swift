import Foundation

public struct ShimmerEffect: Sendable {
    public let baseColor: ANSIColor
    public let highlightColor: ANSIColor
    public let duration: TimeInterval
    public let direction: Direction
    public let width: Double
    
    public enum Direction: Sendable {
        case leftToRight
        case rightToLeft
        case topToBottom
        case bottomToTop
    }
    
    public init(
        baseColor: ANSIColor = .semantic(.primary),
        highlightColor: ANSIColor = .semantic(.accent),
        duration: TimeInterval = 2.0,
        direction: Direction = .leftToRight,
        width: Double = 0.3
    ) {
        self.baseColor = baseColor
        self.highlightColor = highlightColor
        self.duration = duration
        self.direction = direction
        self.width = max(0.1, min(1.0, width))
    }
    

    public static let defaultShimmer = ShimmerEffect()
    
    public static let fastShimmer = ShimmerEffect(
        duration: 1.0,
        width: 0.2
    )
    
    public static let goldShimmer = ShimmerEffect(
        baseColor: .rgb(184, 134, 11),
        highlightColor: .rgb(255, 215, 0),
        duration: 2.5,
        width: 0.4
    )
}

public struct ShimmerEffectView: ConsoleView {
    private let content: AnyConsoleView
    private let effect: ShimmerEffect
    private let isActive: Bool
    
    public init<Content: ConsoleView>(
        effect: ShimmerEffect = .defaultShimmer,
        isActive: Bool = true,
        @ConsoleBuilder content: () -> Content
    ) {
        self.content = AnyConsoleView(content())
        self.effect = effect
        self.isActive = isActive
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {
        var node = content._makeNode(context: &context)
        
        if isActive {
            let shimmerKey = PropertyContainer.Key<Bool>("shimmer")
            let shimmerEffectKey = PropertyContainer.Key<ShimmerEffect>("shimmerEffect")
            let shimmerFrameKey = PropertyContainer.Key<Int>("shimmerFrame")
            
            node = node.with(properties: node.properties
                .with(shimmerKey, value: true)
                .with(shimmerEffectKey, value: effect)
                .with(shimmerFrameKey, value: context.frame)
            )
        }
        
        return node
    }
    
    public var body: Never {
        fatalError("ShimmerEffectView is a modifier")
    }
}

public extension ConsoleView {
    func shimmer(
        baseColor: ANSIColor = .semantic(.primary),
        highlightColor: ANSIColor = .semantic(.accent),
        duration: TimeInterval = 2.0,
        direction: ShimmerEffect.Direction = .leftToRight,
        width: Double = 0.3,
        isActive: Bool = true
    ) -> some ConsoleView {
        ShimmerEffectView(
            effect: ShimmerEffect(
                baseColor: baseColor,
                highlightColor: highlightColor,
                duration: duration,
                direction: direction,
                width: width
            ),
            isActive: isActive
        ) {
            self
        }
    }
    
    func shimmer(
        _ effect: ShimmerEffect = .defaultShimmer,
        isActive: Bool = true
    ) -> some ConsoleView {
        ShimmerEffectView(
            effect: effect,
            isActive: isActive
        ) {
            self
        }
    }
}

public struct ShimmerAnimator: Sendable {
    private let scheduler = AnimationScheduler.shared
    private let runtime = TerminalRuntime.shared
    
    public init() {}
    

    public func startShimmer(
        address: Address,
        effect: ShimmerEffect
    ) async {
        let animationID = AnimationScheduler.AnimationID("shimmer-\(address.raw)")
        
        await scheduler.animate(
            id: animationID,
            duration: effect.duration,
            update: { @Sendable progress in

                let position = Self.calculateShimmerPosition(
                    progress: progress,
                    direction: effect.direction
                )
                

                let commands = Self.generateShimmerCommands(
                    address: address,
                    effect: effect,
                    position: position
                )
                
                await runtime.applyCommands(commands)
            }
        )
    }
    

    public func stopShimmer(address: Address) async {
        let animationID = AnimationScheduler.AnimationID("shimmer-\(address.raw)")
        await scheduler.cancelAnimation(animationID)
        

        await runtime.applyCommands([.reset])
    }
    

    

    static func calculateShimmerPosition(
        progress: Double,
        direction: ShimmerEffect.Direction
    ) -> Double {
        switch direction {
        case .leftToRight, .topToBottom:
            return progress
        case .rightToLeft, .bottomToTop:
            return 1.0 - progress
        }
    }
    

    static func generateShimmerCommands(
        address: Address,
        effect: ShimmerEffect,
        position: Double
    ) -> [RenderCommand] {
        var commands: [RenderCommand] = []
        

        let shimmerIntensity = calculateShimmerIntensity(
            at: position,
            width: effect.width
        )
        

        let color = interpolateColors(
            base: effect.baseColor,
            highlight: effect.highlightColor,
            intensity: shimmerIntensity
        )
        
        commands.append(.setForeground(color))
        
        return commands
    }
    

    static func calculateShimmerIntensity(
        at position: Double,
        width: Double
    ) -> Double {

        let center = position
        let distance = abs(0.5 - center) * 2
        
        if distance > width {
            return 0.0
        }
        

        let normalizedDistance = distance / width
        return 0.5 + 0.5 * cos(normalizedDistance * .pi)
    }
    

    static func interpolateColors(
        base: ANSIColor,
        highlight: ANSIColor,
        intensity: Double
    ) -> ANSIColor {
        let (baseR, baseG, baseB) = extractRGB(from: base)
        let (highlightR, highlightG, highlightB) = extractRGB(from: highlight)
        
        let r = baseR + (highlightR - baseR) * intensity
        let g = baseG + (highlightG - baseG) * intensity
        let b = baseB + (highlightB - baseB) * intensity
        
        return .rgb(
            UInt8(max(0, min(255, r))),
            UInt8(max(0, min(255, g))),
            UInt8(max(0, min(255, b)))
        )
    }
    

    static func extractRGB(from color: ANSIColor) -> (Double, Double, Double) {
        switch color {
        case .rgb(let r, let g, let b):
            return (Double(r), Double(g), Double(b))
        case .semantic(.accent):
            return (0, 122, 255)
        case .semantic(.success):
            return (52, 199, 89)
        case .semantic(.warning):
            return (255, 149, 0)
        case .semantic(.error):
            return (255, 59, 48)
        case .semantic(.primary):
            return (255, 255, 255)
        case .semantic(.secondary):
            return (174, 174, 178)
        case .semantic(.muted):
            return (142, 142, 147)
        case .semantic(.background):
            return (0, 0, 0)
        case .semantic(.foreground):
            return (255, 255, 255)
        case .semantic(.info):
            return (0, 180, 230)
        case .indexed(let index):

            switch index {
            case 0: return (0, 0, 0)
            case 1: return (128, 0, 0)
            case 2: return (0, 128, 0)
            case 3: return (128, 128, 0)
            case 4: return (0, 0, 128)
            case 5: return (128, 0, 128)
            case 6: return (0, 128, 128)
            case 7: return (192, 192, 192)
            case 8: return (128, 128, 128)
            case 9: return (255, 0, 0)
            case 10: return (0, 255, 0)
            case 11: return (255, 255, 0)
            case 12: return (0, 0, 255)
            case 13: return (255, 0, 255)
            case 14: return (0, 255, 255)
            case 15: return (255, 255, 255)
            default: return (255, 255, 255)
            }
        case .xterm256(let index):

            if index < 16 {
                return extractRGB(from: .indexed(index))
            } else {
                return (Double(index), Double(index), Double(index))
            }
        case .none:
            return (255, 255, 255)
        }
    }
}