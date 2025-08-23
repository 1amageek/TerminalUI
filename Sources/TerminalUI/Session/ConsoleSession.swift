import Foundation
import Tracing
import Synchronization

public struct ConsoleSessionID: Hashable, Sendable, CustomStringConvertible {
    private let value: String
    
    init() {
        self.value = UUID().uuidString
    }
    
    public var description: String {
        value
    }
}

public final class ConsoleSession: Sendable {

    public let id: ConsoleSessionID
    

    public let span: any Span
    

    public let options: SessionOptions
    

    private let runtime: TerminalRuntime
    

    private let isActive = Mutex(true)
    
    init(span: any Span, options: SessionOptions, runtime: TerminalRuntime) {
        self.id = ConsoleSessionID()
        self.span = span
        self.options = options
        self.runtime = runtime
        

        span.addEvent("terminalui.session.start")
    }
    

    public func render<V: ConsoleView>(@ConsoleBuilder _ content: @escaping @Sendable () -> V) {
        guard isActive.withLock({ $0 }) else { return }
        
        Task { @Sendable in

            let capabilities = await runtime.capabilities()
            var context = RenderContext(
                terminalWidth: capabilities.width,
                terminalHeight: capabilities.height,
                capabilities: capabilities,
                theme: options.theme,
                frame: 0,
                options: options
            )
            

            let view = content()
            let node = view._makeNode(context: &context)
            

            await runtime.commit(node, options: options)
            

            span.addEvent("terminalui.render")
        }
    }
    

    public func progress(total: Int, label: String? = nil) -> ProgressHandle {
        let handle = ProgressHandle(
            sessionID: id,
            total: total,
            label: label,
            runtime: runtime,
            span: span
        )
        
        span.addEvent("terminalui.progress.start")
        
        return handle
    }
    

    public func spinner(_ label: String? = nil, style: SpinnerStyle = .dots) -> SpinnerHandle {
        let handle = SpinnerHandle(
            sessionID: id,
            label: label,
            style: style,
            runtime: runtime,
            span: span
        )
        
        span.addEvent("terminalui.spinner.start")
        
        return handle
    }
    

    public func log(_ level: LogLevel, _ message: String) {
        guard isActive.withLock({ $0 }) else { return }
        

        span.addEvent("terminalui.log")
        

        if !options.headless {
            Task {
                let color: ANSIColor = switch level {
                case .debug: .semantic(.muted)
                case .info: .semantic(.info)
                case .warning: .semantic(.warning)
                case .error: .semantic(.error)
                }
                
                let commands: [RenderCommand] = [
                    .setForeground(color),
                    .write("[\(level.rawValue.uppercased())] "),
                    .reset,
                    .writeLine(message)
                ]
                
                await runtime.applyCommands(commands)
            }
        }
    }
    

    public func end() {
        isActive.withLock { active in
            guard active else { return }
            active = false
        }
        

        span.addEvent("terminalui.session.end")
        

        Task {
            await runtime.stopAllAnimations()
        }
    }
    

    private func countNodes(_ node: Node) -> Int {
        1 + node.children.reduce(0) { $0 + countNodes($1) }
    }
}

public enum LogLevel: String, Sendable {
    case debug
    case info
    case warning
    case error
}

public struct SpinnerStyle: Sendable {
    public let name: String
    public let frames: [String]
    public let interval: TimeInterval
    
    public init(name: String, frames: [String], interval: TimeInterval = 0.08) {
        self.name = name
        self.frames = frames
        self.interval = interval
    }
    

    public static let dots = SpinnerStyle(
        name: "dots",
        frames: ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
    )
    

    public static let line = SpinnerStyle(
        name: "line",
        frames: ["-", "\\", "|", "/"]
    )
    

    public static let arc = SpinnerStyle(
        name: "arc",
        frames: ["◜", "◠", "◝", "◞", "◡", "◟"]
    )
    

    public static let bounce = SpinnerStyle(
        name: "bounce",
        frames: ["⠁", "⠂", "⠄", "⠂"]
    )
    

    public static let braille = SpinnerStyle(
        name: "braille",
        frames: ["⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷"]
    )
}