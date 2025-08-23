import Foundation

public struct AnyConsoleView: ConsoleView {
    private let makeNode: @Sendable (inout RenderContext) -> Node
    
    public init<V: ConsoleView>(_ view: V) {
        self.makeNode = { context in
            view._makeNode(context: &context)
        }
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {
        makeNode(&context)
    }
    
    public var body: Never {
        fatalError("AnyConsoleView is a primitive view")
    }
}