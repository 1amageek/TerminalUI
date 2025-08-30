import Foundation

/// An interactive button that performs an action when activated
public struct Button: ConsoleView {
    private let label: String
    private let action: @Sendable () -> Void
    private let shortcut: Character?
    private let isDefault: Bool
    private let isDestructive: Bool
    private let isDisabled: Bool
    
    public init(
        _ label: String,
        action: @escaping @Sendable () -> Void
    ) {
        self.label = label
        self.action = action
        self.shortcut = nil
        self.isDefault = false
        self.isDestructive = false
        self.isDisabled = false
    }
    
    private init(
        label: String,
        action: @escaping @Sendable () -> Void,
        shortcut: Character?,
        isDefault: Bool,
        isDestructive: Bool,
        isDisabled: Bool
    ) {
        self.label = label
        self.action = action
        self.shortcut = shortcut
        self.isDefault = isDefault
        self.isDestructive = isDestructive
        self.isDisabled = isDisabled
    }
    
    /// Assigns a keyboard shortcut to the button
    public func keyboardShortcut(_ key: Character) -> Button {
        Button(
            label: label,
            action: action,
            shortcut: key,
            isDefault: isDefault,
            isDestructive: isDestructive,
            isDisabled: isDisabled
        )
    }
    
    /// Marks this button as the default action
    public func buttonStyle(_ style: ButtonStyle) -> Button {
        switch style {
        case .default:
            return Button(
                label: label,
                action: action,
                shortcut: shortcut,
                isDefault: true,
                isDestructive: isDestructive,
                isDisabled: isDisabled
            )
        case .destructive:
            return Button(
                label: label,
                action: action,
                shortcut: shortcut,
                isDefault: isDefault,
                isDestructive: true,
                isDisabled: isDisabled
            )
        case .plain:
            return self
        }
    }
    
    /// Disables the button
    public func disabled(_ isDisabled: Bool = true) -> Button {
        Button(
            label: label,
            action: action,
            shortcut: shortcut,
            isDefault: isDefault,
            isDestructive: isDestructive,
            isDisabled: isDisabled
        )
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {
        var properties = PropertyContainer()
        
        properties = properties.with(.label, value: label)
        
        if let shortcut = shortcut {
            properties = properties.with(.shortcut, value: String(shortcut))
        }
        
        properties = properties
            .with(.isDefault, value: isDefault)
            .with(.isDestructive, value: isDestructive)
            .with(.disabled, value: isDisabled)
        
        // Store action reference - in real implementation would need proper action handling
        // This is a simplified version
        
        return Node(
            address: context.makeAddress(for: "button"),
            logicalID: nil,
            kind: .button,
            properties: properties,
            parentAddress: context.currentParent
        )
    }
    
    public var body: Never {
        fatalError("Button is a primitive view")
    }
}

public enum ButtonStyle {
    case `default`
    case destructive
    case plain
}

// Property keys for Button
public extension PropertyContainer.Key {
    static var shortcut: PropertyContainer.Key<String> { PropertyContainer.Key("shortcut") }
    static var isDefault: PropertyContainer.Key<Bool> { PropertyContainer.Key("isDefault") }
    static var isDestructive: PropertyContainer.Key<Bool> { PropertyContainer.Key("isDestructive") }
    static var disabled: PropertyContainer.Key<Bool> { PropertyContainer.Key("disabled") }
}