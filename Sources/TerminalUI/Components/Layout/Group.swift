import Foundation

public struct Group<Content: ConsoleView>: ConsoleView {
    private let content: Content
    
    public init(@ConsoleBuilder content: () -> Content) {
        self.content = content()
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {

        content._makeNode(context: &context)
    }
}