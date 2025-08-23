import Testing
import Foundation
@testable import TerminalUI

@Test("Node creation from views")
func testNodeCreation() async throws {
    // Create a simple text view
    let text = Text("Hello, World!")
    var context = RenderContext()
    let node = text._makeNode(context: &context)
    
    #expect(node.kind == .text)
    #expect(node.prop(.text, as: String.self) == "Hello, World!")
}

@Test("VStack layout")
func testVStackLayout() async throws {
    let stack = VStack {
        Text("Line 1")
        Text("Line 2")
        Text("Line 3")
    }
    
    var context = RenderContext()
    let node = stack._makeNode(context: &context)
    
    #expect(node.kind == .vstack)
    #expect(node.children.count == 3)
    #expect(node.children.allSatisfy { $0.kind == .text })
}

@Test("HStack layout")
func testHStackLayout() async throws {
    let stack = HStack {
        Text("Column 1")
        Text("Column 2")
    }
    
    var context = RenderContext()
    let node = stack._makeNode(context: &context)
    
    #expect(node.kind == .hstack)
    #expect(node.children.count == 2)
}

@Test("Text modifiers")
func testTextModifiers() async throws {
    let text = Text("Styled")
        .foreground(.semantic(.accent))
        .background(.rgb(255, 0, 0))
        .bold()
        .italic()
        .underline()
        .dim()
    
    var context = RenderContext()
    let node = text._makeNode(context: &context)
    
    #expect(node.prop(.bold, as: Bool.self) == true)
    #expect(node.prop(.italic, as: Bool.self) == true)
    #expect(node.prop(.underline, as: Bool.self) == true)
    #expect(node.prop(.dim, as: Bool.self) == true)
    #expect(node.prop(.foreground, as: String.self) != nil)
    #expect(node.prop(.background, as: String.self) != nil)
}

@Test("Panel with content")
func testPanel() async throws {
    let panel = Panel(title: "Test Panel") {
        VStack {
            Text("Content 1")
            Text("Content 2")
        }
    }
    
    var context = RenderContext()
    let node = panel._makeNode(context: &context)
    
    #expect(node.kind == .panel)
    #expect(node.prop(.label, as: String.self) == "Test Panel")
    #expect(node.children.count == 1)
    #expect(node.children[0].kind == .vstack)
}

@Test("Progress view determinate")
func testProgressDeterminate() async throws {
    let progress = ProgressView(label: "Loading", value: 0.5)
    
    var context = RenderContext()
    let node = progress._makeNode(context: &context)
    
    #expect(node.kind == .progress)
    #expect(node.prop(.label, as: String.self) == "Loading")
    #expect(node.prop(.value, as: Double.self) == 0.5)
    #expect(node.prop(.indeterminate, as: Bool.self) == false)
}

@Test("Progress view indeterminate")
func testProgressIndeterminate() async throws {
    let progress = ProgressView.spinning("Loading")
    
    var context = RenderContext()
    let node = progress._makeNode(context: &context)
    
    #expect(node.kind == .progress)
    #expect(node.prop(.label, as: String.self) == "Loading")
    #expect(node.prop(.indeterminate, as: Bool.self) == true)
}

@Test("Badge creation")
func testBadge() async throws {
    let badge = Badge("NEW").tint(.semantic(.success))
    
    var context = RenderContext()
    let node = badge._makeNode(context: &context)
    
    #expect(node.kind == .badge)
    #expect(node.prop(.text, as: String.self) == "NEW")
    #expect(node.prop(.tint, as: String.self) != nil)
}

@Test("Note with different kinds")
func testNote() async throws {
    let notes = [
        Note("Info", kind: .info),
        Note("Success", kind: .success),
        Note("Warning", kind: .warning),
        Note("Error", kind: .error)
    ]
    
    for note in notes {
        var context = RenderContext()
        let node = note._makeNode(context: &context)
        
        #expect(node.kind == .note)
        #expect(node.prop(.text, as: String.self) != nil)
        #expect(node.prop(.icon, as: String.self) != nil)
    }
}

@Test("Divider styles")
func testDivider() async throws {
    let dividers = [
        Divider().style(.single),
        Divider().style(.double),
        Divider().style(.thick),
        Divider().style(.dashed),
        Divider().style(.dotted)
    ]
    
    for divider in dividers {
        var context = RenderContext()
        let node = divider._makeNode(context: &context)
        
        #expect(node.kind == .divider)
        #expect(node.prop(.text, as: String.self) != nil)
    }
}

@Test("Conditional content")
func testConditionalContent() async throws {
    let showFirst = true
    
    let content = Group {
        if showFirst {
            Text("First")
        } else {
            Text("Second")
        }
    }
    
    var context = RenderContext()
    let node = content._makeNode(context: &context)
    
    // Group passes through its content
    #expect(node.kind == .text)
    #expect(node.prop(.text, as: String.self) == "First")
}

@Test("ForEach with array")
func testForEach() async throws {
    let items = ["Apple", "Banana", "Cherry"]
    
    let list = VStack {
        ForEach(items, id: \.self) { item in
            Text(item)
        }
    }
    
    var context = RenderContext()
    let node = list._makeNode(context: &context)
    
    #expect(node.kind == .vstack)
    // VStack directly contains the text nodes from ForEach
    #expect(node.children.count == 3)
    #expect(node.children[0].kind == .text)
    #expect(node.children[1].kind == .text)
    #expect(node.children[2].kind == .text)
    
    #expect(node.children[0].prop(.text, as: String.self) == "Apple")
    #expect(node.children[1].prop(.text, as: String.self) == "Banana")
    #expect(node.children[2].prop(.text, as: String.self) == "Cherry")
}

@Test("Theme color resolution")
func testThemeColorResolution() async throws {
    let theme = Theme.default
    
    let accentColor = theme.resolve(.accent)
    let successColor = theme.resolve(.success)
    let warningColor = theme.resolve(.warning)
    let errorColor = theme.resolve(.error)
    
    // Just verify they resolve to non-semantic colors
    #expect(accentColor != .semantic(.accent))
    #expect(successColor != .semantic(.success))
    #expect(warningColor != .semantic(.warning))
    #expect(errorColor != .semantic(.error))
}

@Test("Capabilities detection")
func testCapabilitiesDetection() async throws {
    let capabilities = Capabilities.detect()
    
    // Just verify we get some capabilities
    #expect(capabilities.width > 0)
    #expect(capabilities.height > 0)
}

