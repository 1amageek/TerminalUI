import Foundation

public struct LayoutContext {
    public let width: Int
    public let height: Int
    public let theme: Theme
    public var currentX: Int = 0
    public var currentY: Int = 0
    public var availableWidth: Int
    public var availableHeight: Int
    
    public init(width: Int, height: Int, theme: Theme) {
        self.width = width
        self.height = height
        self.theme = theme
        self.availableWidth = width
        self.availableHeight = height
    }
    

    public func child(width: Int? = nil, height: Int? = nil, x: Int = 0, y: Int = 0) -> LayoutContext {
        var context = self
        context.currentX = x
        context.currentY = y
        if let width = width {
            context.availableWidth = min(width, availableWidth)
        }
        if let height = height {
            context.availableHeight = min(height, availableHeight)
        }
        return context
    }
}

public struct LayoutEngine {
    
    public init() {}
    

    public func layout(_ node: Node, context: LayoutContext) -> Node {
        var layoutNode = node
        

        switch node.kind {
        case .vstack:
            layoutNode = layoutVStack(node, context: context)
        case .hstack:
            layoutNode = layoutHStack(node, context: context)
        case .panel:
            layoutNode = layoutPanel(node, context: context)
        case .text:
            layoutNode = layoutText(node, context: context)
        case .divider:
            layoutNode = layoutDivider(node, context: context)
        case .progress:
            layoutNode = layoutProgress(node, context: context)
        default:

            layoutNode = layoutChildren(node, context: context)
        }
        

        let properties = layoutNode.properties
            .with(.width, value: context.availableWidth)
            .with(.height, value: context.availableHeight)
            .with(.x, value: context.currentX)
            .with(.y, value: context.currentY)
        
        return layoutNode.with(properties: properties)
    }
    

    private func layoutChildren(_ node: Node, context: LayoutContext) -> Node {
        let children = node.children.map { child in
            layout(child, context: context)
        }
        return node.with(children: children)
    }
    

    private func layoutVStack(_ node: Node, context: LayoutContext) -> Node {
        let spacing = node.prop(.spacing, as: Int.self) ?? 0
        let padding = node.prop(.padding, as: Int.self) ?? 0
        
        var currentY = context.currentY + padding
        let availableWidth = context.availableWidth - (padding * 2)
        
        var layoutChildren: [Node] = []
        
        for (index, child) in node.children.enumerated() {

            let childHeight = calculateHeight(for: child, width: availableWidth)
            
            let childContext = context.child(
                width: availableWidth,
                height: childHeight,
                x: context.currentX + padding,
                y: currentY
            )
            
            let layoutChild = layout(child, context: childContext)
            layoutChildren.append(layoutChild)
            
            currentY += childHeight
            if index < node.children.count - 1 {
                currentY += spacing
            }
        }
        
        return node.with(children: layoutChildren)
    }
    

    private func layoutHStack(_ node: Node, context: LayoutContext) -> Node {
        let spacing = node.prop(.spacing, as: Int.self) ?? 0
        let padding = node.prop(.padding, as: Int.self) ?? 0
        
        var currentX = context.currentX + padding
        let availableHeight = context.availableHeight - (padding * 2)
        

        let totalSpacing = spacing * max(0, node.children.count - 1)
        let totalPadding = padding * 2
        let availableWidth = context.availableWidth - totalSpacing - totalPadding
        let childWidth = node.children.isEmpty ? 0 : availableWidth / node.children.count
        
        var layoutChildren: [Node] = []
        
        for (index, child) in node.children.enumerated() {
            let childContext = context.child(
                width: childWidth,
                height: availableHeight,
                x: currentX,
                y: context.currentY + padding
            )
            
            let layoutChild = layout(child, context: childContext)
            layoutChildren.append(layoutChild)
            
            currentX += childWidth
            if index < node.children.count - 1 {
                currentX += spacing
            }
        }
        
        return node.with(children: layoutChildren)
    }
    

    private func layoutPanel(_ node: Node, context: LayoutContext) -> Node {
        let hasBorder = node.prop(.border, as: String.self) != nil
        let borderWidth = hasBorder ? 1 : 0
        

        let innerContext = context.child(
            width: context.availableWidth - (borderWidth * 2),
            height: context.availableHeight - (borderWidth * 2),
            x: context.currentX + borderWidth,
            y: context.currentY + borderWidth
        )
        
        let children = node.children.map { child in
            layout(child, context: innerContext)
        }
        
        return node.with(children: children)
    }
    

    private func layoutText(_ node: Node, context: LayoutContext) -> Node {

        return node
    }
    

    private func layoutDivider(_ node: Node, context: LayoutContext) -> Node {

        let properties = node.properties
            .with(.width, value: context.availableWidth)
            .with(.height, value: 1)
        return node.with(properties: properties)
    }
    

    private func layoutProgress(_ node: Node, context: LayoutContext) -> Node {

        let properties = node.properties
            .with(.width, value: context.availableWidth)
            .with(.height, value: 1)
        return node.with(properties: properties)
    }
    

    private func calculateHeight(for node: Node, width: Int) -> Int {
        switch node.kind {
        case .text:

            let text = node.prop(.text, as: String.self) ?? ""
            let lines = (text.count + width - 1) / width
            return max(1, lines)
        case .divider:
            return 1
        case .progress:
            return 1
        case .panel:

            let hasBorder = node.prop(.border, as: String.self) != nil
            let borderHeight = hasBorder ? 2 : 0
            let childrenHeight = node.children.reduce(0) { sum, child in
                sum + calculateHeight(for: child, width: width - (hasBorder ? 2 : 0))
            }
            return childrenHeight + borderHeight
        case .vstack:

            let spacing = node.prop(.spacing, as: Int.self) ?? 0
            let padding = node.prop(.padding, as: Int.self) ?? 0
            let childrenHeight = node.children.enumerated().reduce(0) { sum, item in
                let (index, child) = item
                let height = calculateHeight(for: child, width: width - (padding * 2))
                let spacingHeight = index > 0 ? spacing : 0
                return sum + height + spacingHeight
            }
            return childrenHeight + (padding * 2)
        case .hstack:

            let padding = node.prop(.padding, as: Int.self) ?? 0
            let maxHeight = node.children.reduce(0) { maxH, child in
                max(maxH, calculateHeight(for: child, width: width / max(1, node.children.count)))
            }
            return maxHeight + (padding * 2)
        default:

            return 1
        }
    }
}