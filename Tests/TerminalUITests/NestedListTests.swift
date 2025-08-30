import Testing
import Foundation
@testable import TerminalUI

@Suite("Nested List Tests")
struct NestedListTests {
    
    @Test("Simple nested list structure")
    func testSimpleNestedList() async throws {
        let view = List {
            Text("Item 1")
            List {
                Text("Sub Item 1.1")
                Text("Sub Item 1.2")
            }
            Text("Item 2")
        }
        
        var context = RenderContext()
        let node = view._makeNode(context: &context)
        
        #expect(node.kind == .list)
        #expect(node.children.count == 1)
        
        // The nested structure should be in the child's children
        let childNode = node.children[0]
        #expect(childNode.kind == .group)
        #expect(childNode.children.count == 3)
        
        // Check the structure
        #expect(childNode.children[0].kind == .text)
        #expect(childNode.children[1].kind == .list)
        #expect(childNode.children[2].kind == .text)
    }
    
    @Test("Deeply nested lists")
    func testDeeplyNestedLists() async throws {
        let view = List {
            Text("Level 1")
            List {
                Text("Level 2")
                List {
                    Text("Level 3")
                    List {
                        Text("Level 4")
                    }
                }
            }
        }
        
        var context = RenderContext()
        let node = view._makeNode(context: &context)
        
        #expect(node.kind == .list)
        
        // Check that depth is tracked properly through context
        // The root list should have indentWidth = 0
        #expect(node.properties[.indentWidth] == 0)
    }
    
    @Test("Mixed content in nested lists")
    func testMixedContentInNestedLists() async throws {
        let view = List(style: .numbered) {
            Text("First Item")
            Divider()
            List(style: .bulleted) {
                Text("Bullet 1")
                Text("Bullet 2")
            }
            Spacer()
            Text("Last Item")
        }
        
        var context = RenderContext()
        let node = view._makeNode(context: &context)
        
        #expect(node.kind == .list)
        #expect(node.properties[.kind] == "numbered")
        
        // Check that nested list has different style
        let childNode = node.children[0]
        #expect(childNode.kind == .group)
        #expect(childNode.children.count == 5)
        
        // Find the nested list
        let nestedList = childNode.children[2]
        #expect(nestedList.kind == .list)
        #expect(nestedList.properties[.kind] == "bulleted")
    }
    
    @Test("Legacy ListItem API still works")
    func testLegacyListItemAPI() async throws {
        let items = [
            ListItem(id: "1", content: "Item 1"),
            ListItem(id: "2", content: "Item 2"),
            ListItem(id: "3", content: "Item 3")
        ]
        
        let view = List<EmptyView>(
            items: items,
            style: .checkbox,
            selectedIDs: ["2"]
        )
        
        var context = RenderContext()
        let node = view._makeNode(context: &context)
        
        #expect(node.kind == NodeKind.list)
        #expect(node.properties[PropertyContainer.Key<String>("kind")] == "checkbox")
        
        // Legacy API should store items in properties
        let renderItems: [ListItemData]? = node.properties[PropertyContainer.Key<[ListItemData]>("listItems")]
        #expect(renderItems != nil)
        #expect(renderItems?.count == 3)
        #expect(renderItems?[1].isSelected == true)
    }
    
    @Test("List depth tracking in context")
    func testListDepthTracking() async throws {
        struct DepthTrackingView: ConsoleView {
            let expectedDepth: Int
            
            var body: some ConsoleView {
                EmptyView()
            }
            
            func _makeNode(context: inout RenderContext) -> Node {
                // Verify the depth is what we expect
                precondition(context.listDepth == expectedDepth, 
                           "Expected depth \(expectedDepth), got \(context.listDepth)")
                return Node(
                    address: context.makeAddress(for: "depth-check"),
                    kind: .empty
                )
            }
        }
        
        let view = List {  // depth should be 0 outside, 1 inside
            DepthTrackingView(expectedDepth: 1)
            List {  // depth should be 2 inside
                DepthTrackingView(expectedDepth: 2)
                List {  // depth should be 3 inside
                    DepthTrackingView(expectedDepth: 3)
                }
            }
        }
        
        var context = RenderContext()
        #expect(context.listDepth == 0)
        
        let _ = view._makeNode(context: &context)
        
        // After rendering, context should be back to 0
        #expect(context.listDepth == 0)
    }
}