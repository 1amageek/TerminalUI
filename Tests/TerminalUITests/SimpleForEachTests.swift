import Testing
@testable import TerminalUI

@Suite("Simple ForEach Tests")
struct SimpleForEachTests {
    
    // MARK: - Basic Tests
    
    @Test("ForEach with simple string array")
    func testSimpleStringArray() async throws {
        let items = ["Apple", "Banana", "Cherry"]
        
        let forEach = ForEach(items, id: \.self) { item in
            Text(item)
        }
        
        var context = RenderContext()
        let node = forEach._makeNode(context: &context)
        
        #expect(node.kind == .group)
        #expect(node.children.count == 3)
        
        // Check if all children are text nodes
        for (index, child) in node.children.enumerated() {
            #expect(child.kind == .text)
            #expect(child.prop(.text, as: String.self) == items[index])
        }
    }
    
    @Test("ForEach with Range<Int>")
    func testRangeInt() async throws {
        let forEach = ForEach(0..<5) { index in
            Text("Item \(index)")
        }
        
        var context = RenderContext()
        let node = forEach._makeNode(context: &context)
        
        #expect(node.kind == .group)
        #expect(node.children.count == 5)
        
        for i in 0..<5 {
            #expect(node.children[i].kind == .text)
            #expect(node.children[i].prop(.text, as: String.self) == "Item \(i)")
        }
    }
    
    @Test("ForEach with ClosedRange<Int>")
    func testClosedRangeInt() async throws {
        let forEach = ForEach(1...3) { index in
            Text("Number \(index)")
        }
        
        var context = RenderContext()
        let node = forEach._makeNode(context: &context)
        
        #expect(node.kind == .group)
        #expect(node.children.count == 3)
        #expect(node.children[0].prop(.text, as: String.self) == "Number 1")
        #expect(node.children[1].prop(.text, as: String.self) == "Number 2")
        #expect(node.children[2].prop(.text, as: String.self) == "Number 3")
    }
    
    // MARK: - Identifiable Tests
    
    struct Item: Identifiable, Sendable {
        let id: String
        let name: String
        let value: Int
    }
    
    @Test("ForEach with Identifiable items")
    func testIdentifiable() async throws {
        let items = [
            Item(id: "a", name: "Alpha", value: 1),
            Item(id: "b", name: "Beta", value: 2),
            Item(id: "c", name: "Gamma", value: 3)
        ]
        
        let forEach = ForEach(items) { item in
            Text(item.name)
        }
        
        var context = RenderContext()
        let node = forEach._makeNode(context: &context)
        
        #expect(node.kind == .group)
        #expect(node.children.count == 3)
        #expect(node.children[0].prop(.text, as: String.self) == "Alpha")
        #expect(node.children[1].prop(.text, as: String.self) == "Beta")
        #expect(node.children[2].prop(.text, as: String.self) == "Gamma")
    }
    
    // MARK: - KeyPath Tests
    
    struct CustomItem: Sendable {
        let customId: Int
        let title: String
    }
    
    @Test("ForEach with custom id KeyPath")
    func testCustomKeyPath() async throws {
        let items = [
            CustomItem(customId: 1, title: "First"),
            CustomItem(customId: 2, title: "Second"),
            CustomItem(customId: 3, title: "Third")
        ]
        
        let forEach = ForEach(items, id: \.customId) { item in
            Text(item.title)
        }
        
        var context = RenderContext()
        let node = forEach._makeNode(context: &context)
        
        #expect(node.kind == .group)
        #expect(node.children.count == 3)
        #expect(node.children[0].prop(.text, as: String.self) == "First")
        #expect(node.children[1].prop(.text, as: String.self) == "Second")
        #expect(node.children[2].prop(.text, as: String.self) == "Third")
    }
    
    // MARK: - Stride Tests
    
    @Test("ForEach with stride")
    func testStride() async throws {
        let forEach = ForEach(stride: 0, to: 10, by: 2) { value in
            Text("Value: \(value)")
        }
        
        var context = RenderContext()
        let node = forEach._makeNode(context: &context)
        
        #expect(node.kind == .group)
        #expect(node.children.count == 5) // 0, 2, 4, 6, 8
        #expect(node.children[0].prop(.text, as: String.self) == "Value: 0")
        #expect(node.children[1].prop(.text, as: String.self) == "Value: 2")
        #expect(node.children[2].prop(.text, as: String.self) == "Value: 4")
        #expect(node.children[3].prop(.text, as: String.self) == "Value: 6")
        #expect(node.children[4].prop(.text, as: String.self) == "Value: 8")
    }
    
    // MARK: - Empty Collection Tests
    
    @Test("ForEach with empty collection")
    func testEmptyCollection() async throws {
        let emptyItems: [String] = []
        
        let forEach = ForEach(emptyItems, id: \.self) { item in
            Text(item)
        }
        
        var context = RenderContext()
        let node = forEach._makeNode(context: &context)
        
        #expect(node.kind == .group)
        #expect(node.children.isEmpty)
    }
    
    // MARK: - Complex Content Tests
    
    @Test("ForEach with complex nested content")
    func testComplexContent() async throws {
        let items = [
            Item(id: "1", name: "First", value: 100),
            Item(id: "2", name: "Second", value: 200)
        ]
        
        let forEach = ForEach(items) { item in
            VStack {
                Text(item.name)
                Text("Value: \(item.value)")
            }
        }
        
        var context = RenderContext()
        let node = forEach._makeNode(context: &context)
        
        #expect(node.kind == .group)
        #expect(node.children.count == 2)
        
        // Each child should be a VStack
        for child in node.children {
            #expect(child.kind == .vstack)
            #expect(child.children.count == 2)
            #expect(child.children[0].kind == .text)
            #expect(child.children[1].kind == .text)
        }
    }
    
    // MARK: - Performance Tests
    
    @Test("ForEach with large collection")
    func testLargeCollection() async throws {
        let largeArray = Array(0..<1000)
        
        let forEach = ForEach(largeArray, id: \.self) { value in
            Text("\(value)")
        }
        
        var context = RenderContext()
        let node = forEach._makeNode(context: &context)
        
        #expect(node.kind == .group)
        #expect(node.children.count == 1000)
        
        // Spot check a few values
        #expect(node.children[0].prop(.text, as: String.self) == "0")
        #expect(node.children[500].prop(.text, as: String.self) == "500")
        #expect(node.children[999].prop(.text, as: String.self) == "999")
    }
    
    // MARK: - Filter and Sort Tests
    
    @Test("ForEach with filtered data")
    func testFilteredData() async throws {
        let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        let evenNumbers = numbers.filter { $0 % 2 == 0 }
        
        let forEach = ForEach(evenNumbers, id: \.self) { number in
            Text("\(number)")
        }
        
        var context = RenderContext()
        let node = forEach._makeNode(context: &context)
        
        #expect(node.kind == .group)
        #expect(node.children.count == 5) // 2, 4, 6, 8, 10
        #expect(node.children[0].prop(.text, as: String.self) == "2")
        #expect(node.children[1].prop(.text, as: String.self) == "4")
        #expect(node.children[2].prop(.text, as: String.self) == "6")
        #expect(node.children[3].prop(.text, as: String.self) == "8")
        #expect(node.children[4].prop(.text, as: String.self) == "10")
    }
    
    @Test("ForEach with sorted data")
    func testSortedData() async throws {
        let items = [
            Item(id: "z", name: "Zebra", value: 3),
            Item(id: "a", name: "Apple", value: 1),
            Item(id: "m", name: "Mango", value: 2)
        ]
        
        let sortedItems = items.sorted { $0.name < $1.name }
        
        let forEach = ForEach(sortedItems) { item in
            Text(item.name)
        }
        
        var context = RenderContext()
        let node = forEach._makeNode(context: &context)
        
        #expect(node.kind == .group)
        #expect(node.children.count == 3)
        #expect(node.children[0].prop(.text, as: String.self) == "Apple")
        #expect(node.children[1].prop(.text, as: String.self) == "Mango")
        #expect(node.children[2].prop(.text, as: String.self) == "Zebra")
    }
}