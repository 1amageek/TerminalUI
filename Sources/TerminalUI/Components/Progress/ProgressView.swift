import Foundation

public struct ProgressView: ConsoleView {
    private let label: String?
    private var value: Double?
    private let total: Double
    private var tint: ANSIColor = .semantic(.accent)
    private var showPercentage: Bool = true
    

    public init(label: String? = nil, value: Double, total: Double = 1.0) {
        self.label = label
        self.value = value
        self.total = total
    }
    

    public static func spinning(_ label: String? = nil) -> ProgressView {
        var view = ProgressView(label: label, value: 0, total: 1.0)
        view.value = nil
        return view
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {
        let id = context.makeNodeID(for: "progress")
        
        var properties = PropertyContainer()
            .with(.tint, value: String(describing: tint))
        
        if let label = label {
            properties = properties.with(.label, value: label)
        }
        
        if let value = value {
            properties = properties
                .with(.value, value: value)
                .with(.total, value: total)
                .with(.indeterminate, value: false)
            
            if showPercentage {
                let percentage = Int((value / total) * 100)
                properties = properties.with(.percentage, value: percentage)
            }
        } else {
            properties = properties.with(.indeterminate, value: true)
        }
        
        return Node(
            id: id,
            kind: .progress,
            properties: properties,
            parentID: context.currentParent
        )
    }
}

public extension ProgressView {
    func tint(_ color: ANSIColor) -> Self {
        var copy = self
        copy.tint = color
        return copy
    }
    
    func showPercentage(_ show: Bool) -> Self {
        var copy = self
        copy.showPercentage = show
        return copy
    }
}