import Foundation

public struct TextFieldConfig: Sendable {
    public var placeholder: String?
    public var secure: Bool
    public var singleLine: Bool
    public var maxLength: Int?
    public var imeMode: IMEMode
    public var validate: (@Sendable (String) -> ValidationResult)?
    public var transformOnCommit: (@Sendable (String) -> String)?
    public var selectionEnabled: Bool
    
    public init(
        placeholder: String? = nil,
        secure: Bool = false,
        singleLine: Bool = true,
        maxLength: Int? = nil,
        imeMode: IMEMode = .system,
        validate: (@Sendable (String) -> ValidationResult)? = nil,
        transformOnCommit: (@Sendable (String) -> String)? = nil,
        selectionEnabled: Bool = false
    ) {
        self.placeholder = placeholder
        self.secure = secure
        self.singleLine = singleLine
        self.maxLength = maxLength
        self.imeMode = imeMode
        self.validate = validate
        self.transformOnCommit = transformOnCommit
        self.selectionEnabled = selectionEnabled
    }
    
    public static let `default` = TextFieldConfig()
}

public enum IMEMode: Sendable {
    case system
    case inlineExperimental
}

public enum SubmitTrigger: Sendable {
    case enter
    case tab
    case focusLoss
}

@MainActor 
public struct TextField: @preconcurrency ConsoleView {
    private let label: String?
    @Binding private var text: String
    private var config: TextFieldConfig
    private var onChange: (@Sendable (String) -> Void)?
    private var onSubmit: (SubmitTrigger, @Sendable (String) -> Void)?
    @Binding private var isFocused: Bool
    
    public init(
        _ label: String? = nil,
        text: Binding<String>,
        config: TextFieldConfig = .default
    ) {
        self.label = label
        self._text = text
        self.config = config
        self._isFocused = Binding(wrappedValue: false)
    }
    

    
    public func onChange(_ handler: @Sendable @escaping (String) -> Void) -> Self {
        var copy = self
        copy.onChange = handler
        return copy
    }
    
    public func onSubmit(
        _ when: SubmitTrigger = .enter,
        _ handler: @Sendable @escaping (String) -> Void
    ) -> Self {
        var copy = self
        copy.onSubmit = (when, handler)
        return copy
    }
    
    public func focused(_ isFocused: Binding<Bool>) -> Self {
        var copy = self
        copy._isFocused = isFocused
        return copy
    }
    
    public func placeholder(_ text: String) -> Self {
        var copy = self
        copy.config.placeholder = text
        return copy
    }
    
    public func secure(_ flag: Bool = true) -> Self {
        var copy = self
        copy.config.secure = flag
        return copy
    }
    
    public func maxLength(_ length: Int) -> Self {
        var copy = self
        copy.config.maxLength = length
        return copy
    }
    
    public func validate(_ validator: @escaping @Sendable (String) -> ValidationResult) -> Self {
        var copy = self
        copy.config.validate = validator
        return copy
    }
    

    
    @MainActor
    public func _makeNode(context: inout RenderContext) -> Node {
        var properties = PropertyContainer()
        

        if let label = label {
            properties = properties.with(.label, value: label)
        }
        

        if config.secure {
            let masked = String(repeating: "●", count: text.count)
            properties = properties.with(.text, value: masked)
        } else {
            properties = properties.with(.text, value: text)
        }
        

        if let placeholder = config.placeholder, text.isEmpty {
            properties = properties.with(.placeholder, value: placeholder)
        }
        

        properties = properties.with(.focused, value: isFocused)
        

        if let validate = config.validate {
            let result = validate(text)
            let validationKey = PropertyContainer.Key<String>("validation")
            switch result {
            case .ok:
                break
            case .warning(let msg):
                properties = properties.with(validationKey, value: "warning:\(msg)")
            case .error(let msg):
                properties = properties.with(validationKey, value: "error:\(msg)")
            }
        }
        

        properties = properties.with(.secure, value: config.secure)
        let singleLineKey = PropertyContainer.Key<Bool>("singleLine")
        properties = properties.with(singleLineKey, value: config.singleLine)
        
        if let maxLength = config.maxLength {
            let maxLengthKey = PropertyContainer.Key<Int>("maxLength")
            properties = properties.with(maxLengthKey, value: maxLength)
        }
        
        return Node(id: context.makeNodeID(), kind: .textfield, properties: properties)
    }
    
    public var body: Never {
        fatalError("TextField is a leaf component")
    }
}