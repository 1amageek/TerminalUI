import Foundation

// MARK: - ForEach View

/// A view that creates views from a collection of data with stable logical IDs
public struct ForEach<Data, ID, Content>: @unchecked Sendable, ConsoleView 
where Data: RandomAccessCollection & Sendable, 
      ID: Hashable & Sendable, 
      Content: ConsoleView {
    
    internal let data: Data
    internal let identifier: IDExtractor
    internal let content: @Sendable (Data.Element) -> Content
    
    /// How to extract IDs from elements
    internal enum IDExtractor {
        case keyPath(KeyPath<Data.Element, ID>)
        case closure(@Sendable (Data.Element) -> ID)
    }
    
    internal init(
        data: Data,
        identifier: IDExtractor,
        content: @escaping @Sendable (Data.Element) -> Content
    ) {
        self.data = data
        self.identifier = identifier
        self.content = content
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {
        context.pushPath("foreach")
        defer { context.popPath() }
        
        var children: [Node] = []
        
        #if DEBUG
        var seenIDs: Set<String> = []
        #endif
        
        for element in data {
            // Extract the ID from the element
            let id: ID = switch identifier {
            case .keyPath(let kp):
                element[keyPath: kp]
            case .closure(let f):
                f(element)
            }
            
            // Convert to stable string representation
            let idString = stableString(from: id)
            
            #if DEBUG
            // Check for duplicate IDs in debug builds
            if seenIDs.contains(idString) {
                preconditionFailure(
                    "Duplicate ID '\(idString)' found in ForEach at path: \(context.currentPath.joined(separator: ".")). " +
                    "Each element must have a unique ID."
                )
            }
            seenIDs.insert(idString)
            #endif
            
            // Generate child node with unique path
            context.pushPath("item[\(idString)]")
            var childNode = content(element)._makeNode(context: &context)
            
            // Ensure the child has the logical ID set
            if childNode.logicalID == nil {
                childNode = childNode.with(logicalID: LogicalID(idString))
            }
            
            context.popPath()
            
            children.append(childNode)
        }
        
        return Node(
            address: context.makeAddress(for: "foreach"),
            logicalID: nil, // ForEach itself doesn't need a logical ID
            kind: .group,
            children: children,
            properties: PropertyContainer(),
            parentAddress: context.currentParent
        )
    }
    
    public var body: Never {
        fatalError("ForEach is a primitive view")
    }
}

// Note: IDExtractor cannot conform to Sendable because KeyPath is not Sendable

extension ForEach {
    /// Convert any Hashable ID to a stable string representation
    private func stableString<T: Hashable>(from value: T) -> String {
        switch value {
        case let string as String:
            return string
        case let uuid as UUID:
            return uuid.uuidString
        case let int as Int:
            return String(int)
        case let int8 as Int8:
            return String(int8)
        case let int16 as Int16:
            return String(int16)
        case let int32 as Int32:
            return String(int32)
        case let int64 as Int64:
            return String(int64)
        case let uint as UInt:
            return String(uint)
        case let uint8 as UInt8:
            return String(uint8)
        case let uint16 as UInt16:
            return String(uint16)
        case let uint32 as UInt32:
            return String(uint32)
        case let uint64 as UInt64:
            return String(uint64)
        case let float as Float:
            return String(float)
        case let double as Double:
            return String(double)
        case let bool as Bool:
            return String(bool)
        case let describable as CustomStringConvertible:
            return describable.description
        default:
            // For other types, use a deterministic string representation
            // This includes the type name to avoid collisions
            return "\(type(of: value)):\(String(describing: value))"
        }
    }
}

// MARK: - ForEach Initializers

extension ForEach {
    /// Create a ForEach with an explicit ID key path
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
    
    /// Create a ForEach with an ID extraction closure
    public init(
        _ data: Data,
        id: @escaping @Sendable (Data.Element) -> ID,
        @ConsoleBuilder content: @escaping @Sendable (Data.Element) -> Content
    ) where Data.Element: Sendable {
        self.init(
            data: data,
            identifier: .closure(id),
            content: content
        )
    }
}

// MARK: - Identifiable Support

extension ForEach where Data.Element: Identifiable, ID == Data.Element.ID {
    /// Create a ForEach from Identifiable elements
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

// MARK: - Hashable Element Support

extension ForEach where Data.Element: Hashable, ID == Data.Element {
    /// Create a ForEach where elements themselves are the IDs
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

// MARK: - Range Support

extension ForEach where Data == Range<Int>, ID == Int {
    /// Create a ForEach from a range of integers
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
    /// Create a ForEach from a closed range of integers
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

// MARK: - Enumerated Support

extension ForEach {
    /// Create a ForEach with enumerated elements
    /// Note: This uses indices as IDs, which is not stable across data changes
    /// Consider using proper IDs from your data model instead
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

// MARK: - Stride Support

extension ForEach {
    /// Create a ForEach from a stride
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
    
    /// Create a ForEach from a stride through
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

// MARK: - Section Support

/// A configuration for sections in ForEach
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