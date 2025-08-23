import Foundation

@resultBuilder
public struct ConsoleBuilder {
    

    public static func buildBlock<V: ConsoleView>(_ view: V) -> V {
        view
    }
    

    public static func buildBlock() -> EmptyView {
        EmptyView()
    }
    

    public static func buildBlock<each V: ConsoleView>(_ views: repeat each V) -> TupleView<(repeat each V)> {
        TupleView((repeat each views))
    }
    

    public static func buildOptional<V: ConsoleView>(_ view: V?) -> ConditionalContent<V, EmptyView> {
        if let view = view {
            return ConditionalContent(first: view)
        } else {
            return ConditionalContent(second: EmptyView())
        }
    }
    

    public static func buildEither<First: ConsoleView, Second: ConsoleView>(
        first: First
    ) -> ConditionalContent<First, Second> {
        ConditionalContent(first: first)
    }
    

    public static func buildEither<First: ConsoleView, Second: ConsoleView>(
        second: Second
    ) -> ConditionalContent<First, Second> {
        ConditionalContent(second: second)
    }
    

    public static func buildArray<V: ConsoleView>(_ views: [V]) -> some ConsoleView {

        Group {
            ForEach(Array(views.enumerated()), id: \.offset) { _, view in
                view
            }
        }
    }
    

    public static func buildLimitedAvailability<V: ConsoleView>(_ view: V) -> V {
        view
    }
    

    public static func buildExpression<V: ConsoleView>(_ expression: V) -> V {
        expression
    }
}

public struct TupleView<Content: Sendable>: ConsoleView {
    let content: Content
    
    public init(_ content: Content) {
        self.content = content
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {
        var children: [Node] = []
        

        let mirror = Mirror(reflecting: content)
        for child in mirror.children {
            if let view = child.value as? any ConsoleView {
                children.append(view._makeNode(context: &context))
            }
        }
        
        let id = context.makeNodeID(for: "tuple")
        return Node(
            id: id,
            kind: .group,
            children: children
        )
    }
}

public struct ConditionalContent<First: ConsoleView, Second: ConsoleView>: ConsoleView {
    enum Storage {
        case first(First)
        case second(Second)
    }
    
    private let storage: Storage
    
    init(first: First) {
        self.storage = .first(first)
    }
    
    init(second: Second) {
        self.storage = .second(second)
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {
        switch storage {
        case .first(let view):
            return view._makeNode(context: &context)
        case .second(let view):
            return view._makeNode(context: &context)
        }
    }
}