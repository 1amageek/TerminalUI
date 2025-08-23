import Foundation

public actor AnimationScheduler {
    private var animations: [AnimationID: AnimationTask] = [:]
    private let maxFPS: Int
    private let frameInterval: TimeInterval
    

    public static let shared = AnimationScheduler()
    
    private init(maxFPS: Int = 15) {
        self.maxFPS = maxFPS
        self.frameInterval = 1.0 / Double(maxFPS)
    }
    

    public struct AnimationID: Hashable, Sendable {
        private let value: String
        
        public init(_ value: String = UUID().uuidString) {
            self.value = value
        }
    }
    

    private struct AnimationTask {
        let id: AnimationID
        let duration: TimeInterval
        let startTime: Date
        let update: @Sendable (Double) async -> Void
        let completion: (@Sendable () async -> Void)?
        let task: Task<Void, Never>
        
        var elapsedTime: TimeInterval {
            Date().timeIntervalSince(startTime)
        }
        
        var progress: Double {
            min(1.0, elapsedTime / duration)
        }
        
        var isComplete: Bool {
            elapsedTime >= duration
        }
    }
    

    

    @discardableResult
    public func animate(
        id: AnimationID = AnimationID(),
        duration: TimeInterval,
        update: @escaping @Sendable (Double) async -> Void,
        completion: (@Sendable () async -> Void)? = nil
    ) -> AnimationID {

        cancelAnimation(id)
        

        let task = Task { [weak self] in
            guard let self = self else { return }
            
            let startTime = Date()
            var lastFrameTime = startTime
            
            while !Task.isCancelled {
                let now = Date()
                let elapsed = now.timeIntervalSince(startTime)
                let progress = min(1.0, elapsed / duration)
                

                await update(progress)
                

                if progress >= 1.0 {
                    break
                }
                

                let nextFrameTime = lastFrameTime.addingTimeInterval(self.frameInterval)
                let sleepTime = nextFrameTime.timeIntervalSince(now)
                
                if sleepTime > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(sleepTime * 1_000_000_000))
                }
                
                lastFrameTime = nextFrameTime
            }
            

            if !Task.isCancelled {
                await completion?()
            }
            

            await self.removeAnimation(id)
        }
        

        let animation = AnimationTask(
            id: id,
            duration: duration,
            startTime: Date(),
            update: update,
            completion: completion,
            task: task
        )
        
        animations[id] = animation
        
        return id
    }
    

    public func cancelAnimation(_ id: AnimationID) {
        if let animation = animations[id] {
            animation.task.cancel()
            animations.removeValue(forKey: id)
        }
    }
    

    public func cancelAllAnimations() {
        for animation in animations.values {
            animation.task.cancel()
        }
        animations.removeAll()
    }
    

    public func isAnimating(_ id: AnimationID) -> Bool {
        animations[id] != nil
    }
    

    public func progress(for id: AnimationID) -> Double? {
        animations[id]?.progress
    }
    

    
    private func removeAnimation(_ id: AnimationID) {
        animations.removeValue(forKey: id)
    }
}

public enum Easing {

    public static func linear(_ t: Double) -> Double {
        t
    }
    

    public static func easeIn(_ t: Double) -> Double {
        t * t
    }
    

    public static func easeOut(_ t: Double) -> Double {
        t * (2 - t)
    }
    

    public static func easeInOut(_ t: Double) -> Double {
        t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t
    }
    

    public static func easeInCubic(_ t: Double) -> Double {
        t * t * t
    }
    

    public static func easeOutCubic(_ t: Double) -> Double {
        let t1 = t - 1
        return t1 * t1 * t1 + 1
    }
    

    public static func easeInOutCubic(_ t: Double) -> Double {
        t < 0.5 ? 4 * t * t * t : (t - 1) * (2 * t - 2) * (2 * t - 2) + 1
    }
    

    public static func bounce(_ t: Double) -> Double {
        if t < 1/2.75 {
            return 7.5625 * t * t
        } else if t < 2/2.75 {
            let t1 = t - 1.5/2.75
            return 7.5625 * t1 * t1 + 0.75
        } else if t < 2.5/2.75 {
            let t1 = t - 2.25/2.75
            return 7.5625 * t1 * t1 + 0.9375
        } else {
            let t1 = t - 2.625/2.75
            return 7.5625 * t1 * t1 + 0.984375
        }
    }
    

    public static func elastic(_ t: Double) -> Double {
        if t == 0 || t == 1 { return t }
        let p = 0.3
        let a = 1.0
        let s = p / 4
        let t1 = t - 1
        return -a * pow(2, 10 * t1) * sin((t1 - s) * 2 * .pi / p)
    }
}

public extension AnimationScheduler {

    func animateValue<T: BinaryFloatingPoint & Sendable>(
        from start: T,
        to end: T,
        duration: TimeInterval,
        easing: @escaping @Sendable (Double) -> Double = Easing.linear,
        update: @escaping @Sendable (T) async -> Void
    ) -> AnimationID {
        animate(duration: duration) { progress in
            let easedProgress = easing(progress)
            let value = start + (end - start) * T(easedProgress)
            await update(value)
        }
    }
    

    func animateColor(
        from start: (r: Double, g: Double, b: Double),
        to end: (r: Double, g: Double, b: Double),
        duration: TimeInterval,
        easing: @escaping @Sendable (Double) -> Double = Easing.linear,
        update: @escaping @Sendable (_ r: Double, _ g: Double, _ b: Double) async -> Void
    ) -> AnimationID {
        animate(duration: duration) { progress in
            let easedProgress = easing(progress)
            let r = start.r + (end.r - start.r) * easedProgress
            let g = start.g + (end.g - start.g) * easedProgress
            let b = start.b + (end.b - start.b) * easedProgress
            await update(r, g, b)
        }
    }
}