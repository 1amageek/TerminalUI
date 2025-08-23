import Foundation
import Tracing
import Synchronization

public protocol LiveHandle: Sendable {

    func finish()
}

public final class ProgressHandle: LiveHandle {
    private let sessionID: ConsoleSessionID
    private let total: Int
    private let runtime: TerminalRuntime
    private let span: any Span
    private let state: Mutex<ProgressState>
    
    private struct ProgressState {
        var current: Int = 0
        var label: String?
        var isFinished: Bool = false
    }
    
    init(sessionID: ConsoleSessionID, total: Int, label: String?, runtime: TerminalRuntime, span: any Span) {
        self.sessionID = sessionID
        self.total = total
        self.runtime = runtime
        self.span = span
        self.state = Mutex(ProgressState(label: label))
    }
    

    public func update(_ current: Int) {
        let (wasFinished, oldCurrent) = state.withLock { state in
            let wasFinished = state.isFinished
            let oldCurrent = state.current
            if !wasFinished {
                state.current = min(current, total)
            }
            return (wasFinished, oldCurrent)
        }
        
        guard !wasFinished && current != oldCurrent else { return }
        

        Task {
            let progress = Double(current) / Double(max(1, total))
            let nodeID = NodeID("progress-\(sessionID)")
            
            let commands: [RenderCommand] = [
                .frame(nodeID, FramePayload(
                    frame: current,
                    progress: progress
                ))
            ]
            
            await runtime.applyCommands(commands)
        }
        

        span.addEvent("terminalui.progress.update")
    }
    

    public func label(_ text: String) -> ProgressHandle {
        state.withLock { state in
            state.label = text
        }
        return self
    }
    

    public func finish(with status: Status = .success(nil)) {
        let wasFinished = state.withLock { state in
            let wasFinished = state.isFinished
            state.isFinished = true
            return wasFinished
        }
        
        guard !wasFinished else { return }
        

        span.addEvent("terminalui.progress.finish")
    }
    

    public func finish() {
        finish(with: .success(nil))
    }
}

public final class SpinnerHandle: LiveHandle {
    private let sessionID: ConsoleSessionID
    private let style: SpinnerStyle
    private let runtime: TerminalRuntime
    private let span: any Span
    private let state: Mutex<SpinnerState>
    private let animationTask: Task<Void, Never>
    
    private struct SpinnerState {
        var label: String?
        var isFinished: Bool = false
    }
    
    init(sessionID: ConsoleSessionID, label: String?, style: SpinnerStyle, runtime: TerminalRuntime, span: any Span) {
        self.sessionID = sessionID
        self.style = style
        self.runtime = runtime
        self.span = span
        self.state = Mutex(SpinnerState(label: label))
        

        self.animationTask = Task {
            let nodeID = NodeID("spinner-\(sessionID)")
            var frameIndex = 0
            
            while !Task.isCancelled {
                let frame = style.frames[frameIndex % style.frames.count]
                let commands: [RenderCommand] = [
                    .setText(nodeID, frame)
                ]
                
                await runtime.applyCommands(commands)
                
                frameIndex += 1
                try? await Task.sleep(nanoseconds: UInt64(style.interval * 1_000_000_000))
            }
        }
    }
    

    public func label(_ text: String) -> SpinnerHandle {
        state.withLock { state in
            state.label = text
        }
        return self
    }
    

    public func finish<V: ConsoleView>(_ replacement: (@Sendable () -> V)? = nil) {
        let wasFinished = state.withLock { state in
            let wasFinished = state.isFinished
            state.isFinished = true
            return wasFinished
        }
        
        guard !wasFinished else { return }
        

        animationTask.cancel()
        

        if let replacement = replacement {
            Task { @Sendable [replacement] in
                var context = RenderContext()
                let view = replacement()
                let node = view._makeNode(context: &context)
                await runtime.commit(node, options: .default)
            }
        }
        

        span.addEvent("terminalui.spinner.finish")
    }
    

    public func finish() {
        finish(nil as (@Sendable () -> EmptyView)?)
    }
}

public enum Status: Sendable {
    case success(String?)
    case warning(String?)
    case error(String?)
}