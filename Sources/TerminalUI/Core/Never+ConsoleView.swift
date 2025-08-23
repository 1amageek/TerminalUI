import Foundation

extension Never: ConsoleView {
    public func _makeNode(context: inout RenderContext) -> Node {
        fatalError("Never cannot create nodes")
    }
    
    public var body: Never {
        fatalError("Never has no body")
    }
}