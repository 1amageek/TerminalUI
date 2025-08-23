import Testing
@testable import TerminalUI

@Suite("Simple ForEach Tests")
struct SimpleForEachTests {
    
    // MARK: - Basic Tests
    
    @Test("ForEach with simple string array")
    func testSimpleStringArray() async throws {
        let items = ["Apple", "Banana", "Cherry"]
        
        let forEach = ForEach(items) { item in
            Text(item)
        }
        
        var context = RenderContext()
        let node = forEach._makeNode(context: &context)
        
        #expect(node.kind == .group)
        #expect(node.children.count == 3)
        
        // Check if all children are text nodes
        for (index, child) in node.children.enumerated() {
            #expect(child.kind == .text)
            #expect(child.props["text"] as? String == items[index])
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
            #expect(node.children[i].props["text"] as? String == "Item \(i)")
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
        #expect(node.children[0].props["text"] as? String == "Number 1")
        #expect(node.children[1].props["text"] as? String == "Number 2")
        #expect(node.children[2].props["text"] as? String == "Number 3")
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
        #expect(node.children[0].props["text"] as? String == "Alpha")
        #expect(node.children[1].props["text"] as? String == "Beta")
        #expect(node.children[2].props["text"] as? String == "Gamma")
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
        #expect(node.children[0].props["text"] as? String == "First")
        #expect(node.children[1].props["text"] as? String == "Second")
        #expect(node.children[2].props["text"] as? String == "Third")
    }
    
    // MARK: - Dictionary Tests
    
    @Test("ForEach with dictionary")
    func testDictionary() async throws {
        let scores: [String: Int] = [
            "Alice": 95,
            "Bob": 87,
            "Charlie": 92
        ]
        
        let forEach = ForEach(scores) { name, score in
            Text("\(name): \(score)")
        }
        
        var context = RenderContext()
        let node = forEach._makeNode(context: &context)
        
        #expect(node.kind == .group)
        #expect(node.children.count == 3)
        
        // Dictionary order is not guaranteed, so we check if all entries exist
        let textValues = node.children.compactMap { $0.props["text"] as? String }
        #expect(textValues.contains("Alice: 95"))
        #expect(textValues.contains("Bob: 87"))
        #expect(textValues.contains("Charlie: 92"))
    }
    
    // MARK: - Enumerated Tests
    
    @Test("ForEach enumerated")
    func testEnumerated() async throws {
        let fruits = ["Apple", "Banana", "Cherry"]
        
        let forEach = ForEach(enumerated: fruits) { offset, fruit in
            Text("\(offset + 1). \(fruit)")
        }
        
        var context = RenderContext()
        let node = forEach._makeNode(context: &context)
        
        #expect(node.kind == .group)
        #expect(node.children.count == 3)
        #expect(node.children[0].props["text"] as? String == "1. Apple")
        #expect(node.children[1].props["text"] as? String == "2. Banana")
        #expect(node.children[2].props["text"] as? String == "3. Cherry")
    }
    
    // MARK: - Indexed Tests
    
    @Test("ForEach indexed")
    func testIndexed() async throws {
        let colors = ["Red", "Green", "Blue"]
        
        let forEach = ForEach(indexed: colors) { index, color in
            Text("\(index): \(color)")
        }
        
        var context = RenderContext()
        let node = forEach._makeNode(context: &context)
        
        #expect(node.kind == .group)
        #expect(node.children.count == 3)
        #expect(node.children[0].props["text"] as? String == "0: Red")
        #expect(node.children[1].props["text"] as? String == "1: Green")
        #expect(node.children[2].props["text"] as? String == "2: Blue")
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
        #expect(node.children[0].props["text"] as? String == "Value: 0")
        #expect(node.children[1].props["text"] as? String == "Value: 2")
        #expect(node.children[2].props["text"] as? String == "Value: 4")
        #expect(node.children[3].props["text"] as? String == "Value: 6")
        #expect(node.children[4].props["text"] as? String == "Value: 8")
    }
    
    // MARK: - Empty Collection Tests
    
    @Test("ForEach with empty collection")
    func testEmptyCollection() async throws {
        let emptyItems: [String] = []
        
        let forEach = ForEach(emptyItems) { item in
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
        
        let forEach = ForEach(largeArray) { value in
            Text("\(value)")
        }
        
        var context = RenderContext()
        let node = forEach._makeNode(context: &context)
        
        #expect(node.kind == .group)
        #expect(node.children.count == 1000)
        
        // Spot check a few values
        #expect(node.children[0].props["text"] as? String == "0")
        #expect(node.children[500].props["text"] as? String == "500")
        #expect(node.children[999].props["text"] as? String == "999")
    }
    
    // MARK: - Filter and Sort Tests
    
    @Test("ForEach with filtered data")
    func testFilteredData() async throws {
        let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        let evenNumbers = numbers.filter { $0 % 2 == 0 }
        
        let forEach = ForEach(evenNumbers) { number in
            Text("\(number)")
        }
        
        var context = RenderContext()
        let node = forEach._makeNode(context: &context)
        
        #expect(node.kind == .group)
        #expect(node.children.count == 5) // 2, 4, 6, 8, 10
        #expect(node.children[0].props["text"] as? String == "2")
        #expect(node.children[1].props["text"] as? String == "4")
        #expect(node.children[2].props["text"] as? String == "6")
        #expect(node.children[3].props["text"] as? String == "8")
        #expect(node.children[4].props["text"] as? String == "10")
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
        #expect(node.children[0].props["text"] as? String == "Apple")
        #expect(node.children[1].props["text"] as? String == "Mango")
        #expect(node.children[2].props["text"] as? String == "Zebra")
    }
}