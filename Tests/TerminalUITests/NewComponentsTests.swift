import Testing
import Foundation
@testable import TerminalUI

@Suite("New Components Tests")
struct NewComponentsTests {
    
    @Test("Spacer creation")
    func testSpacer() async throws {
        let spacer = Spacer()
        var context = RenderContext()
        let node = spacer._makeNode(context: &context)
        
        #expect(node.kind == .spacer)
        #expect(node.prop(.flexible, as: Bool.self) == true)
    }
    
    @Test("Spacer with minimum length")
    func testSpacerWithMinLength() async throws {
        let spacer = Spacer(minLength: 10)
        var context = RenderContext()
        let node = spacer._makeNode(context: &context)
        
        #expect(node.kind == .spacer)
        #expect(node.prop(.minLength, as: Int.self) == 10)
        #expect(node.prop(.flexible, as: Bool.self) == false)
    }
    
    @Test("Button creation")
    func testButton() async throws {
        let button = Button("Click Me") { 
            // action
        }
        var context = RenderContext()
        let node = button._makeNode(context: &context)
        
        #expect(node.kind == .button)
        #expect(node.prop(.label, as: String.self) == "Click Me")
    }
    
    @Test("Button with shortcut")
    func testButtonWithShortcut() async throws {
        let button = Button("Save") { }
            .keyboardShortcut("s")
        
        var context = RenderContext()
        let node = button._makeNode(context: &context)
        
        #expect(node.kind == .button)
        #expect(node.prop(.shortcut, as: String.self) == "s")
    }
    
    @Test("Button styles")
    func testButtonStyles() async throws {
        let defaultButton = Button("OK") { }
            .buttonStyle(.default)
        
        let destructiveButton = Button("Delete") { }
            .buttonStyle(.destructive)
        
        var context = RenderContext()
        
        let defaultNode = defaultButton._makeNode(context: &context)
        #expect(defaultNode.prop(.isDefault, as: Bool.self) == true)
        
        let destructiveNode = destructiveButton._makeNode(context: &context)
        #expect(destructiveNode.prop(.isDestructive, as: Bool.self) == true)
    }
    
    @Test("Selector creation")
    func testSelector() async throws {
        let selector = Selector(title: "Choose Option") {
            VStack {
                Text("Option 1")
                Text("Option 2")
                Text("Option 3")
            }
        }
        
        var context = RenderContext()
        let node = selector._makeNode(context: &context)
        
        #expect(node.kind == .selector)
        #expect(node.prop(.label, as: String.self) == "Choose Option")
        #expect(node.children.count == 1)
    }
    
    @Test("Complex layout with new components")
    func testComplexLayout() async throws {
        let view = VStack {
            Text("Header")
            Spacer()
            
            Selector(title: "Actions") {
                VStack {
                    Button("Run") { }.keyboardShortcut("r")
                    Button("Stop") { }.keyboardShortcut("s")
                    Button("Cancel") { }
                        .buttonStyle(.destructive)
                        .keyboardShortcut("c")
                }
            }
            
            Spacer(minLength: 2)
            Text("Footer")
        }
        
        var context = RenderContext()
        let node = view._makeNode(context: &context)
        
        #expect(node.kind == .vstack)
        #expect(node.children.count == 5)
        
        // Check the structure
        #expect(node.children[0].kind == .text) // Header
        #expect(node.children[1].kind == .spacer) // Spacer
        #expect(node.children[2].kind == .selector) // Selector
        #expect(node.children[3].kind == .spacer) // Spacer with min length
        #expect(node.children[4].kind == .text) // Footer
    }
}