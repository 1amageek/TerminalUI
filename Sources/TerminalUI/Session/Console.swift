import Foundation
import Tracing
import Synchronization

public enum Console {

    private static let sessions = Mutex<[String: ConsoleSession]>([:])
    

    private static let currentSession = Mutex<ConsoleSession?>(nil)
    

    public static func start(on span: any Span, options: SessionOptions = .default) -> ConsoleSession {
        let runtime = TerminalRuntime.shared
        let session = ConsoleSession(span: span, options: options, runtime: runtime)
        

        let spanID = "\(type(of: span))-\(UUID().uuidString)"
        sessions.withLock { sessions in
            sessions[spanID] = session
        }
        

        currentSession.withLock { current in
            if current == nil {
                current = session
            }
        }
        

        
        return session
    }
    

    public static var current: ConsoleSession? {
        currentSession.withLock { $0 }
    }
    

    public static func session(withID id: ConsoleSessionID) -> ConsoleSession? {
        return sessions.withLock { sessions in
            sessions.values.first { $0.id == id }
        }
    }
    

    internal static func clearAll() {
        sessions.withLock { sessions in
            for session in sessions.values {
                session.end()
            }
            sessions.removeAll()
        }
        currentSession.withLock { current in
            current = nil
        }
    }
}

public extension Span {

    func startConsole(options: SessionOptions = .default) -> ConsoleSession {
        Console.start(on: self, options: options)
    }
}

protocol InstrumentedSpan: Span {
    func addCallback(_ callback: @escaping (any Span) -> Void)
}

extension Span {
    func addCallbackIfSupported(_ callback: @escaping (any Span) -> Void) {
        if let instrumented = self as? InstrumentedSpan {
            instrumented.addCallback(callback)
        }
    }
}