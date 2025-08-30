import Testing
@testable import TerminalUI

@Suite("ForEach Tests")
struct ForEachTests {
    
    // MARK: - Basic ForEach Tests
    
    @Test("ForEach with simple array")
    func testSimpleArray() async throws {
        let items = ["Apple", "Banana", "Cherry"]
        
        let view = VStack {
            ForEach(items, id: \.self) { item in
                Text(item)
            }
        }
        
        var context = RenderContext()
        let node = view._makeNode(context: &context)
        
        #expect(node.kind == .vstack)
        #expect(node.children.count == 3)
        #expect(node.children[0].kind == .text)
        #expect(node.children[1].kind == .text)
        #expect(node.children[2].kind == .text)
    }
    
    @Test("ForEach with Range<Int>")
    func testRangeInt() async throws {
        let view = VStack {
            ForEach(0..<5) { index in
                Text("Item \(index)")
            }
        }
        
        var context = RenderContext()
        let node = view._makeNode(context: &context)
        
        #expect(node.kind == .vstack)
        #expect(node.children.count == 5)
        for i in 0..<5 {
            #expect(node.children[i].kind == .text)
            #expect(node.children[i].prop(.text, as: String.self) == "Item \(i)")
        }
    }
    
    @Test("ForEach with ClosedRange<Int>")
    func testClosedRangeInt() async throws {
        let view = VStack {
            ForEach(1...3) { index in
                Text("Number \(index)")
            }
        }
        
        var context = RenderContext()
        let node = view._makeNode(context: &context)
        
        #expect(node.kind == .vstack)
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
        
        let view = VStack {
            ForEach(items) { item in
                HStack {
                    Text(item.name)
                    Text("Value: \(item.value)")
                }
            }
        }
        
        var context = RenderContext()
        let node = view._makeNode(context: &context)
        
        #expect(node.kind == .vstack)
        #expect(node.children.count == 3)
        
        for child in node.children {
            #expect(child.kind == .hstack)
            #expect(child.children.count == 2)
        }
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
        
        let view = VStack {
            ForEach(items, id: \.customId) { item in
                Text(item.title)
            }
        }
        
        var context = RenderContext()
        let node = view._makeNode(context: &context)
        
        #expect(node.kind == .vstack)
        #expect(node.children.count == 3)
        #expect(node.children[0].prop(.text, as: String.self) == "First")
        #expect(node.children[1].prop(.text, as: String.self) == "Second")
        #expect(node.children[2].prop(.text, as: String.self) == "Third")
    }
    
    
    
    
    // MARK: - Filtered and Sorted ForEach Tests
    
    @Test("ForEach with filtered data")
    func testFilteredForEach() async throws {
        let numbers = [
            Item(id: "1", name: "One", value: 1),
            Item(id: "2", name: "Two", value: 2),
            Item(id: "3", name: "Three", value: 3),
            Item(id: "4", name: "Four", value: 4),
            Item(id: "5", name: "Five", value: 5)
        ]
        
        let view = VStack {
            ForEach(numbers.filter { $0.value > 2 }) { item in
                Text("\(item.name): \(item.value)")
            }
        }
        
        var context = RenderContext()
        let node = view._makeNode(context: &context)
        
        #expect(node.kind == .vstack)
        #expect(node.children.count == 3) // Only 3, 4, 5 should be included
    }
    
    @Test("ForEach with sorted data")
    func testSortedForEach() async throws {
        let items = [
            Item(id: "z", name: "Zebra", value: 3),
            Item(id: "a", name: "Apple", value: 1),
            Item(id: "m", name: "Mango", value: 2)
        ]
        
        let view = VStack {
            ForEach(items.sorted { $0.name < $1.name }) { item in
                Text(item.name)
            }
        }
        
        var context = RenderContext()
        let node = view._makeNode(context: &context)
        
        #expect(node.kind == .vstack)
        #expect(node.children.count == 3)
        #expect(node.children[0].prop(.text, as: String.self) == "Apple")
        #expect(node.children[1].prop(.text, as: String.self) == "Mango")
        #expect(node.children[2].prop(.text, as: String.self) == "Zebra")
    }
    
    // MARK: - Stride ForEach Tests
    
    @Test("ForEach with stride")
    func testStrideForEach() async throws {
        let view = VStack {
            ForEach(stride: 0, to: 10, by: 2) { value in
                Text("Value: \(value)")
            }
        }
        
        var context = RenderContext()
        let node = view._makeNode(context: &context)
        
        #expect(node.kind == .vstack)
        #expect(node.children.count == 5) // 0, 2, 4, 6, 8
        #expect(node.children[0].prop(.text, as: String.self) == "Value: 0")
        #expect(node.children[1].prop(.text, as: String.self) == "Value: 2")
        #expect(node.children[4].prop(.text, as: String.self) == "Value: 8")
    }
    
    // MARK: - Nested ForEach Tests
    
    @Test("Nested ForEach")
    func testNestedForEach() async throws {
        let matrix = [
            ["A1", "A2", "A3"],
            ["B1", "B2", "B3"],
            ["C1", "C2", "C3"]
        ]
        
        let view = VStack {
            ForEach(0..<matrix.count) { row in
                HStack {
                    ForEach(0..<matrix[row].count) { col in
                        Text(matrix[row][col])
                    }
                }
            }
        }
        
        var context = RenderContext()
        let node = view._makeNode(context: &context)
        
        #expect(node.kind == .vstack)
        #expect(node.children.count == 3)
        
        for (rowIndex, rowNode) in node.children.enumerated() {
            #expect(rowNode.kind == .hstack)
            #expect(rowNode.children.count == 3)
            
            for (colIndex, cellNode) in rowNode.children.enumerated() {
                #expect(cellNode.kind == .text)
                #expect(cellNode.prop(.text, as: String.self) == matrix[rowIndex][colIndex])
            }
        }
    }
    
    // MARK: - Empty ForEach Tests
    
    @Test("ForEach with empty collection")
    func testEmptyForEach() async throws {
        let emptyItems: [String] = []
        
        let view = VStack {
            ForEach(emptyItems) { item in
                Text(item)
            }
        }
        
        var context = RenderContext()
        let node = view._makeNode(context: &context)
        
        #expect(node.kind == .vstack)
        #expect(node.children.isEmpty)
    }
    
    // MARK: - Complex Content Tests
    
    @Test("ForEach with complex content")
    func testComplexContent() async throws {
        let items = [
            Item(id: "1", name: "First", value: 100),
            Item(id: "2", name: "Second", value: 200)
        ]
        
        let view = VStack {
            ForEach(items) { item in
                Panel(title: item.name) {
                    VStack {
                        Text("ID: \(item.id)")
                        Divider()
                        HStack {
                            Text("Value:")
                            Text("\(item.value)").bold()
                        }
                    }
                }
            }
        }
        
        var context = RenderContext()
        let node = view._makeNode(context: &context)
        
        #expect(node.kind == .vstack)
        #expect(node.children.count == 2)
        
        for child in node.children {
            #expect(child.kind == .panel)
            // Panel should have nested content
            #expect(!child.children.isEmpty)
        }
    }
}