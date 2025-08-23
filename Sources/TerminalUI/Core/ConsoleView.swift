import Foundation

public protocol ConsoleView: Sendable {

    associatedtype Body: ConsoleView
    

    func _makeNode(context: inout RenderContext) -> Node
    

    @ConsoleBuilder
    var body: Body { get }
}

public extension ConsoleView {
    var body: Never {
        fatalError("\(Self.self) is a primitive view")
    }
}

public extension ConsoleView where Body == Never {
    func _makeNode(context: inout RenderContext) -> Node {

        fatalError("\(Self.self) must implement _makeNode")
    }
}

public extension ConsoleView where Body: ConsoleView {
    func _makeNode(context: inout RenderContext) -> Node {
        body._makeNode(context: &context)
    }
}

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
}

public struct EmptyView: ConsoleView {
    public init() {}
    
    public func _makeNode(context: inout RenderContext) -> Node {
        Node(id: context.makeNodeID(), kind: .empty, children: [], properties: PropertyContainer())
    }
}

extension Never: ConsoleView {
    public var body: Never {
        fatalError("Never.body should not be called")
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {
        fatalError("Never._makeNode should not be called")
    }
}