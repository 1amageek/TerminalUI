import Foundation

public struct PropertyContainer: Sendable, Equatable {

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
    
    public static func == (lhs: PropertyContainer, rhs: PropertyContainer) -> Bool {
        // Compare storage dictionaries by converting to comparable representation
        guard lhs.storage.count == rhs.storage.count else { return false }
        
        for (key, lhsValue) in lhs.storage {
            guard let rhsValue = rhs.storage[key] else { return false }
            
            // Compare values using string representation as a fallback
            // This is not perfect but works for most cases
            let lhsString = String(describing: lhsValue)
            let rhsString = String(describing: rhsValue)
            if lhsString != rhsString {
                return false
            }
        }
        
        return true
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
    static var showBadges: PropertyContainer.Key<Bool> { PropertyContainer.Key("showBadges") }
    static var bold: PropertyContainer.Key<Bool> { PropertyContainer.Key("bold") }
    static var italic: PropertyContainer.Key<Bool> { PropertyContainer.Key("italic") }
    static var underline: PropertyContainer.Key<Bool> { PropertyContainer.Key("underline") }
    static var dim: PropertyContainer.Key<Bool> { PropertyContainer.Key("dim") }
    

    static var lines: PropertyContainer.Key<[String]> { PropertyContainer.Key("lines") }
    

    static var spacing: PropertyContainer.Key<Int> { PropertyContainer.Key("spacing") }
    static var padding: PropertyContainer.Key<Int> { PropertyContainer.Key("padding") }
    static var border: PropertyContainer.Key<String> { PropertyContainer.Key("border") }
    static var rounded: PropertyContainer.Key<Bool> { PropertyContainer.Key("rounded") }
    

    static var foreground: PropertyContainer.Key<String> { PropertyContainer.Key("foreground") }
    static var background: PropertyContainer.Key<String> { PropertyContainer.Key("background") }
    static var tint: PropertyContainer.Key<String> { PropertyContainer.Key("tint") }
    static var backgroundColor: PropertyContainer.Key<String> { PropertyContainer.Key("backgroundColor") }
    static var color: PropertyContainer.Key<String> { PropertyContainer.Key("color") }
    static var unit: PropertyContainer.Key<String> { PropertyContainer.Key("unit") }
    static var kind: PropertyContainer.Key<String> { PropertyContainer.Key("kind") }
    static var frames: PropertyContainer.Key<[String]> { PropertyContainer.Key("frames") }
    static var icon: PropertyContainer.Key<String> { PropertyContainer.Key("icon") }
    

    

    static var columns: PropertyContainer.Key<[TableColumn]> { PropertyContainer.Key("columns") }
    static var rows: PropertyContainer.Key<[TableRow]> { PropertyContainer.Key("rows") }
    static var columnWidths: PropertyContainer.Key<[String: Int]> { PropertyContainer.Key("columnWidths") }
    static var borderStyle: PropertyContainer.Key<String> { PropertyContainer.Key("borderStyle") }
    static var items: PropertyContainer.Key<[TreeItem]> { PropertyContainer.Key("items") }
    static var listItems: PropertyContainer.Key<[ListItemData]> { PropertyContainer.Key("listItems") }
}


private protocol AnyPropertyKey {
    var name: String { get }
}

extension PropertyContainer.Key: AnyPropertyKey {

}


// MARK: - Codable support removed
// PropertyContainer's Codable support has been removed because it only handled String values.
// If persistence is needed in the future, consider implementing a proper serialization strategy
// that handles all supported types (Bool, Int, Double, arrays, structs, etc.)

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