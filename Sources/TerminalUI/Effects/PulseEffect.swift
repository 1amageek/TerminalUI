import Foundation

public struct PulseEffect: Sendable {
    public enum PulseType: Sendable {
        case color(baseColor: ANSIColor, pulseColor: ANSIColor)
        case scale(maxScale: Double)
        case brightness(maxBrightness: Double)
    }
    
    public let type: PulseType
    public let duration: TimeInterval
    public let cycles: Int?
    public let easing: EasingFunction
    
    public init(
        type: PulseType,
        duration: TimeInterval = 1.0,
        cycles: Int? = nil,
        easing: EasingFunction = .easeInOut
    ) {
        self.type = type
        self.duration = duration
        self.cycles = cycles
        self.easing = easing
    }
    

    public static let colorPulse = PulseEffect(
        type: .color(baseColor: .semantic(.primary), pulseColor: .semantic(.accent)),
        duration: 2.0
    )
    
    public static let scalePulse = PulseEffect(
        type: .scale(maxScale: 1.2),
        duration: 1.5
    )
    
    public static let brightnessPulse = PulseEffect(
        type: .brightness(maxBrightness: 1.5),
        duration: 1.0
    )
}

public enum EasingFunction: Sendable {
    case linear
    case easeIn
    case easeOut
    case easeInOut
    
    public func apply(_ t: Double) -> Double {
        switch self {
        case .linear:
            return t
        case .easeIn:
            return t * t
        case .easeOut:
            return 1.0 - (1.0 - t) * (1.0 - t)
        case .easeInOut:
            return t < 0.5 ? 2 * t * t : 1.0 - 2 * (1.0 - t) * (1.0 - t)
        }
    }
}

public struct PulseAnimator: Sendable {
    private let scheduler = AnimationScheduler.shared
    private let runtime = TerminalRuntime.shared
    
    public init() {}
    

    public func startPulse(
        nodeID: NodeID,
        effect: PulseEffect
    ) async {
        let animationID = AnimationScheduler.AnimationID("pulse-\(nodeID.value)")
        
        await scheduler.animate(
            id: animationID,
            duration: effect.duration,
            update: { @Sendable progress in

                let easedProgress = effect.easing.apply(progress)
                

                let intensity = Self.calculatePulseIntensity(progress: easedProgress)
                

                let commands = Self.generatePulseCommands(
                    nodeID: nodeID,
                    effect: effect,
                    intensity: intensity
                )
                
                await runtime.applyCommands(commands)
            }
        )
    }
    

    public func stopPulse(nodeID: NodeID) async {
        let animationID = AnimationScheduler.AnimationID("pulse-\(nodeID.value)")
        await scheduler.cancelAnimation(animationID)
    }
    

    

    static func calculatePulseIntensity(progress: Double) -> Double {

        return 0.5 + 0.5 * sin(progress * 2 * .pi)
    }
    

    static func generatePulseCommands(
        nodeID: NodeID,
        effect: PulseEffect,
        intensity: Double
    ) -> [RenderCommand] {
        switch effect.type {
        case .color(let baseColor, let pulseColor):
            return generateColorPulseCommands(
                nodeID: nodeID,
                baseColor: baseColor,
                pulseColor: pulseColor,
                intensity: intensity
            )
        case .scale(let maxScale):
            return generateScalePulseCommands(
                nodeID: nodeID,
                maxScale: maxScale,
                intensity: intensity
            )
        case .brightness(let maxBrightness):
            return generateBrightnessPulseCommands(
                nodeID: nodeID,
                maxBrightness: maxBrightness,
                intensity: intensity
            )
        }
    }
    

    static func generateColorPulseCommands(
        nodeID: NodeID,
        baseColor: ANSIColor,
        pulseColor: ANSIColor,
        intensity: Double
    ) -> [RenderCommand] {

        let (baseR, baseG, baseB) = extractRGB(from: baseColor)
        let (pulseR, pulseG, pulseB) = extractRGB(from: pulseColor)
        

        let r = baseR + (pulseR - baseR) * intensity
        let g = baseG + (pulseG - baseG) * intensity
        let b = baseB + (pulseB - baseB) * intensity
        
        return [.setForeground(.rgb(UInt8(r), UInt8(g), UInt8(b)))]
    }
    

    static func generateScalePulseCommands(
        nodeID: NodeID,
        maxScale: Double,
        intensity: Double
    ) -> [RenderCommand] {

        let scaledIntensity = 1.0 + (maxScale - 1.0) * intensity
        
        if scaledIntensity > 1.1 {
            return [.setStyle(.bold)]
        } else if scaledIntensity < 0.9 {
            return [.setStyle(.dim)]
        } else {
            return [.reset]
        }
    }
    

    static func generateBrightnessPulseCommands(
        nodeID: NodeID,
        maxBrightness: Double,
        intensity: Double
    ) -> [RenderCommand] {

        let brightness = 1.0 + (maxBrightness - 1.0) * intensity
        
        if brightness > 1.2 {
            return [.setStyle(.bold)]
        } else if brightness < 0.8 {
            return [.setStyle(.dim)]
        } else {
            return [.reset]
        }
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
        default:
            return (255, 255, 255)
        }
    }
}