import Foundation

public struct PropertyContainer: Sendable {

    public struct Key<Value: Sendable>: Sendable, Hashable {
        let name: String
        let type: Value.Type
        
        public init(_ name: String) { 
            self.name = name
            self.type = Value.self
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
            hasher.combine(ObjectIdentifier(type))
        }
        
        public static func == (lhs: Key<Value>, rhs: Key<Value>) -> Bool {
            lhs.name == rhs.name && lhs.type == rhs.type
        }
    }
    
    private nonisolated(unsafe) let storage: [AnyHashable: any Sendable]
    
    public init() {
        self.storage = [:]
    }
    
    private init(storage: [AnyHashable: any Sendable]) {
        self.storage = storage
    }
    

    public func get<Value: Sendable>(_ key: Key<Value>) -> Value? {
        storage[AnyHashable(key)] as? Value
    }
    

    public func with<Value: Sendable>(_ key: Key<Value>, value: Value) -> PropertyContainer {
        var newStorage = storage
        newStorage[AnyHashable(key)] = value
        return PropertyContainer(storage: newStorage)
    }
    

    public func without<Value: Sendable>(_ key: Key<Value>) -> PropertyContainer {
        var newStorage = storage
        newStorage.removeValue(forKey: AnyHashable(key))
        return PropertyContainer(storage: newStorage)
    }
    

    public func contains<Value: Sendable>(_ key: Key<Value>) -> Bool {
        storage[AnyHashable(key)] != nil
    }
    

    public var allKeys: [String] {
        storage.keys.compactMap { key in
            if let propertyKey = key.base as? AnyPropertyKey {
                return propertyKey.name
            }
            return nil
        }
    }
}

public extension PropertyContainer {

    subscript<Value: Sendable>(_ key: Key<Value>) -> Value? {
        get { get(key) }
    }
    

    subscript<Value: Sendable>(_ key: Key<Value>, default defaultValue: Value) -> Value {
        get { get(key) ?? defaultValue }
    }
}

public extension PropertyContainer.Key {

    static var text: PropertyContainer.Key<String> { PropertyContainer.Key("text") }
    static var label: PropertyContainer.Key<String> { PropertyContainer.Key("label") }
    static var placeholder: PropertyContainer.Key<String> { PropertyContainer.Key("placeholder") }
    static var content: PropertyContainer.Key<String> { PropertyContainer.Key("content") }
    static var language: PropertyContainer.Key<String> { PropertyContainer.Key("language") }
    

    static var width: PropertyContainer.Key<Int> { PropertyContainer.Key("width") }
    static var height: PropertyContainer.Key<Int> { PropertyContainer.Key("height") }
    static var value: PropertyContainer.Key<Double> { PropertyContainer.Key("value") }
    static var progress: PropertyContainer.Key<Double> { PropertyContainer.Key("progress") }
    static var total: PropertyContainer.Key<Double> { PropertyContainer.Key("total") }
    static var current: PropertyContainer.Key<Double> { PropertyContainer.Key("current") }
    static var frameIndex: PropertyContainer.Key<Int> { PropertyContainer.Key("frameIndex") }
    static var min: PropertyContainer.Key<Double> { PropertyContainer.Key("min") }
    static var max: PropertyContainer.Key<Double> { PropertyContainer.Key("max") }
    static var normalizedValue: PropertyContainer.Key<Double> { PropertyContainer.Key("normalizedValue") }
    static var segments: PropertyContainer.Key<Int> { PropertyContainer.Key("segments") }
    static var indentWidth: PropertyContainer.Key<Int> { PropertyContainer.Key("indentWidth") }
    static var percentage: PropertyContainer.Key<Int> { PropertyContainer.Key("percentage") }
    static var x: PropertyContainer.Key<Int> { PropertyContainer.Key("x") }
    static var y: PropertyContainer.Key<Int> { PropertyContainer.Key("y") }
    

    static var isEnabled: PropertyContainer.Key<Bool> { PropertyContainer.Key("isEnabled") }
    static var isVisible: PropertyContainer.Key<Bool> { PropertyContainer.Key("isVisible") }
    static var isSelected: PropertyContainer.Key<Bool> { PropertyContainer.Key("isSelected") }
    static var indeterminate: PropertyContainer.Key<Bool> { PropertyContainer.Key("indeterminate") }
    static var showLineNumbers: PropertyContainer.Key<Bool> { PropertyContainer.Key("showLineNumbers") }
    static var focused: PropertyContainer.Key<Bool> { PropertyContainer.Key("focused") }
    static var secure: PropertyContainer.Key<Bool> { PropertyContainer.Key("secure") }
    static var isAnimating: PropertyContainer.Key<Bool> { PropertyContainer.Key("isAnimating") }
    static var showValue: PropertyContainer.Key<Bool> { PropertyContainer.Key("showValue") }
    static var showHeader: PropertyContainer.Key<Bool> { PropertyContainer.Key("showHeader") }
    static var showBorder: PropertyContainer.Key<Bool> { PropertyContainer.Key("showBorder") }
    static var striped: PropertyContainer.Key<Bool> { PropertyContainer.Key("striped") }
    static var compact: PropertyContainer.Key<Bool> { PropertyContainer.Key("compact") }
    static var showIcons: PropertyContainer.Key<Bool> { PropertyContainer.Key("showIcons") }
    static var showLines: PropertyContainer.Key<Bool> { PropertyContainer.Key("showLines") }
    static var inverted: PropertyContainer.Key<Bool> { PropertyContainer.Key("inverted") }
    static var bold: PropertyContainer.Key<Bool> { PropertyContainer.Key("bold") }
    static var italic: PropertyContainer.Key<Bool> { PropertyContainer.Key("italic") }
    static var underline: PropertyContainer.Key<Bool> { PropertyContainer.Key("underline") }
    static var dim: PropertyContainer.Key<Bool> { PropertyContainer.Key("dim") }
    

    static var lines: PropertyContainer.Key<[String]> { PropertyContainer.Key("lines") }
    static var highlightLines: PropertyContainer.Key<[Int]> { PropertyContainer.Key("highlightLines") }
    static var frames: PropertyContainer.Key<[String]> { PropertyContainer.Key("frames") }
    

    static var spacing: PropertyContainer.Key<Int> { PropertyContainer.Key("spacing") }
    static var padding: PropertyContainer.Key<Int> { PropertyContainer.Key("padding") }
    static var border: PropertyContainer.Key<String> { PropertyContainer.Key("border") }
    static var rounded: PropertyContainer.Key<Bool> { PropertyContainer.Key("rounded") }
    

    static var foreground: PropertyContainer.Key<String> { PropertyContainer.Key("foreground") }
    static var background: PropertyContainer.Key<String> { PropertyContainer.Key("background") }
    static var tint: PropertyContainer.Key<String> { PropertyContainer.Key("tint") }
    static var backgroundColor: PropertyContainer.Key<String> { PropertyContainer.Key("backgroundColor") }
    static var lineNumberColor: PropertyContainer.Key<String> { PropertyContainer.Key("lineNumberColor") }
    static var color: PropertyContainer.Key<String> { PropertyContainer.Key("color") }
    static var unit: PropertyContainer.Key<String> { PropertyContainer.Key("unit") }
    static var icon: PropertyContainer.Key<String> { PropertyContainer.Key("icon") }
    static var kind: PropertyContainer.Key<String> { PropertyContainer.Key("kind") }
    

    static var colors: PropertyContainer.Key<[String: String]> { PropertyContainer.Key("colors") }
    

    static var columns: PropertyContainer.Key<[TableColumn]> { PropertyContainer.Key("columns") }
    static var rows: PropertyContainer.Key<[TableRow]> { PropertyContainer.Key("rows") }
    static var items: PropertyContainer.Key<[TreeItem]> { PropertyContainer.Key("items") }
    static var gridData: PropertyContainer.Key<GridData> { PropertyContainer.Key("gridData") }
    static var listItems: PropertyContainer.Key<[ListItemData]> { PropertyContainer.Key("listItems") }
    static var pairs: PropertyContainer.Key<[KeyValuePair]> { PropertyContainer.Key("pairs") }
}

public struct TableColumn: Sendable, Hashable {
    public let title: String
    public let key: String
    public let width: Int?
    public let alignment: TableAlignment
    
    public init(title: String, key: String, width: Int? = nil, alignment: TableAlignment = .left) {
        self.title = title
        self.key = key
        self.width = width
        self.alignment = alignment
    }
}

public struct TableRow: Sendable, Hashable {
    public let cells: [String: String]
    public let style: TableRowStyle
    
    public init(cells: [String: String], style: TableRowStyle = .normal) {
        self.cells = cells
        self.style = style
    }
}

public struct TreeItem: Sendable, Hashable {
    public let id: String
    public let label: String
    public let icon: String?
    public let children: [TreeItem]
    public let isExpanded: Bool
    public let level: Int
    public let linePrefix: String
    
    public init(id: String, label: String, icon: String? = nil, children: [TreeItem] = [], isExpanded: Bool = false, level: Int = 0, linePrefix: String = "") {
        self.id = id
        self.label = label
        self.icon = icon
        self.children = children
        self.isExpanded = isExpanded
        self.level = level
        self.linePrefix = linePrefix
    }
}

public struct GridData: Sendable, Hashable {
    public let columns: [GridColumn]
    public let rows: [[String]]
    
    public init(columns: [GridColumn], rows: [[String]]) {
        self.columns = columns
        self.rows = rows
    }
}

public struct GridColumn: Sendable, Hashable {
    public let title: String
    public let width: Int?
    public let alignment: TableAlignment
    
    public init(title: String, width: Int? = nil, alignment: TableAlignment = .left) {
        self.title = title
        self.width = width
        self.alignment = alignment
    }
}

public struct ListItemData: Sendable, Hashable {
    public let id: String
    public let content: String
    public let icon: String
    public let badge: String
    public let style: String
    public let isSelected: Bool
    public let bullet: String
    
    public init(
        id: String,
        content: String,
        icon: String = "",
        badge: String = "",
        style: String = "normal",
        isSelected: Bool = false,
        bullet: String = ""
    ) {
        self.id = id
        self.content = content
        self.icon = icon
        self.badge = badge
        self.style = style
        self.isSelected = isSelected
        self.bullet = bullet
    }
}

public struct KeyValuePair: Sendable, Hashable {
    public let key: String
    public let value: String
    
    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}

public enum TableAlignment: String, Sendable, CaseIterable {
    case left
    case center  
    case right
}

public enum TableRowStyle: String, Sendable, CaseIterable {
    case normal
    case header
    case highlighted
    case dimmed
}

private protocol AnyPropertyKey {
    var name: String { get }
}

extension PropertyContainer.Key: AnyPropertyKey {

}

public extension PropertyContainer {

    struct Builder {
        internal var container = PropertyContainer()
        
        public init() {}
        
        internal init(container: PropertyContainer) {
            self.container = container
        }
        
        public mutating func set<Value: Sendable>(_ key: PropertyContainer.Key<Value>, _ value: Value) -> Builder {
            container = container.with(key, value: value)
            return self
        }
        
        public func build() -> PropertyContainer {
            container
        }
    }
    

    func builder() -> Builder {
        Builder(container: self)
    }
}

extension PropertyContainer: Codable {
    private struct CodableEntry: Codable {
        let key: String
        let value: Data
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let entries = try container.decode([CodableEntry].self)
        
        var storage: [AnyHashable: any Sendable] = [:]
        for entry in entries {

            if let stringValue = String(data: entry.value, encoding: .utf8) {
                let key = PropertyContainer.Key<String>(entry.key)
                storage[AnyHashable(key)] = stringValue
            }
        }
        
        self.storage = storage
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let entries: [CodableEntry] = storage.compactMap { (key, value) in
            guard let propertyKey = key.base as? AnyPropertyKey,
                  let stringValue = value as? String else {
                return nil
            }
            
            let data = stringValue.data(using: .utf8) ?? Data()
            return CodableEntry(key: propertyKey.name, value: data)
        }
        
        try container.encode(entries)
    }
}

extension PropertyContainer: CustomDebugStringConvertible {
    public var debugDescription: String {
        let keyValuePairs = storage.map { key, value in
            if let propertyKey = key.base as? AnyPropertyKey {
                return "\(propertyKey.name): \(value)"
            }
            return "\(key): \(value)"
        }
        
        return "PropertyContainer([\(keyValuePairs.joined(separator: ", "))])"
    }
}