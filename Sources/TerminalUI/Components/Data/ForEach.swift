import Foundation

public struct ForEach<Data, ID, Content>: ConsoleView 
where Data: RandomAccessCollection & Sendable, ID: Hashable & Sendable, Content: ConsoleView {
    internal let data: Data
    internal nonisolated(unsafe) let identifier: Identifier
    internal let content: @Sendable (Data.Element) -> Content
    

    internal enum Identifier {
        case keyPath(KeyPath<Data.Element, ID>)
        case closure(@Sendable (Data.Element) -> ID)
        case identity
    }
    

    internal init(
        data: Data,
        identifier: Identifier,
        content: @escaping @Sendable (Data.Element) -> Content
    ) {
        self.data = data
        self.identifier = identifier
        self.content = content
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {
        let children = data.map { element in
            content(element)._makeNode(context: &context)
        }
        
        let nodeId = context.makeNodeID(for: "foreach")
        return Node(
            id: nodeId,
            kind: .group,
            children: children
        )
    }
    
    public var body: Never {
        fatalError("ForEach is a primitive view")
    }
}

extension ForEach {

    public init(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        @ConsoleBuilder content: @escaping @Sendable (Data.Element) -> Content
    ) where Data.Element: Sendable {
        self.init(
            data: data,
            identifier: .keyPath(id),
            content: content
        )
    }
}

extension ForEach where Data.Element: Identifiable, ID == Data.Element.ID {

    public init(
        _ data: Data,
        @ConsoleBuilder content: @escaping @Sendable (Data.Element) -> Content
    ) where Data.Element: Sendable {
        self.init(
            data: data,
            identifier: .closure { $0.id },
            content: content
        )
    }
}

extension ForEach where Data.Element: Hashable, ID == Data.Element {

    public init(
        _ data: Data,
        @ConsoleBuilder content: @escaping @Sendable (Data.Element) -> Content
    ) where Data.Element: Sendable {
        self.init(
            data: data,
            identifier: .closure { $0 },
            content: content
        )
    }
}

extension ForEach where Data == Range<Int>, ID == Int {

    public init(
        _ data: Range<Int>,
        @ConsoleBuilder content: @escaping @Sendable (Int) -> Content
    ) {
        self.init(
            data: data,
            identifier: .closure { $0 },
            content: content
        )
    }
}

extension ForEach where Data == ClosedRange<Int>, ID == Int {

    public init(
        _ data: ClosedRange<Int>,
        @ConsoleBuilder content: @escaping @Sendable (Int) -> Content
    ) {
        self.init(
            data: data,
            identifier: .closure { $0 },
            content: content
        )
    }
}

extension ForEach {

    public init<C: RandomAccessCollection>(
        enumerated data: C,
        @ConsoleBuilder content: @escaping @Sendable (Int, C.Element) -> Content
    ) where Data == Array<(offset: Int, element: C.Element)>, ID == Int, C.Element: Sendable {
        let enumeratedData = Array(data.enumerated())
        self.init(
            data: enumeratedData,
            identifier: .closure { $0.offset },
            content: { item in content(item.offset, item.element) }
        )
    }
}

extension ForEach {

    public init(
        stride from: Int,
        to: Int,
        by: Int,
        @ConsoleBuilder content: @escaping @Sendable (Int) -> Content
    ) where Data == [Int], ID == Int {
        let strideData = Array(Swift.stride(from: from, to: to, by: by))
        self.init(
            data: strideData,
            identifier: .closure { $0 },
            content: content
        )
    }
    

    public init(
        stride from: Int,
        through: Int,
        by: Int,
        @ConsoleBuilder content: @escaping @Sendable (Int) -> Content
    ) where Data == [Int], ID == Int {
        let strideData = Array(Swift.stride(from: from, through: through, by: by))
        self.init(
            data: strideData,
            identifier: .closure { $0 },
            content: content
        )
    }
}

extension ForEach {

    public init<C: RandomAccessCollection>(
        indexed data: C,
        @ConsoleBuilder content: @escaping @Sendable (Int, C.Element) -> Content
    ) where Data == Array<(index: Int, element: C.Element)>, ID == Int, C.Element: Sendable {
        let indexedData = data.enumerated().map { (index: $0.offset, element: $0.element) }
        self.init(
            data: indexedData,
            identifier: .closure { $0.index },
            content: { item in content(item.index, item.element) }
        )
    }
}

public struct SectionConfiguration: Identifiable, Sendable {
    public let id = UUID().uuidString
    public let header: (any ConsoleView)?
    public let footer: (any ConsoleView)?
    public let content: any ConsoleView
    
    public init(
        header: (any ConsoleView)? = nil,
        footer: (any ConsoleView)? = nil,
        @ConsoleBuilder content: () -> any ConsoleView
    ) {
        self.header = header
        self.footer = footer
        self.content = content()
    }
}