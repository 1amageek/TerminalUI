import Foundation

public struct Group<Content: ConsoleView>: ConsoleView {
    public let content: Content
    
    public init(@ConsoleBuilder content: () -> Content) {
        self.content = content()
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {
        // Group is special - it doesn't wrap its content, just passes it through
        content._makeNode(context: &context)
    }
    
    public var body: some ConsoleView {
        content
    }
}