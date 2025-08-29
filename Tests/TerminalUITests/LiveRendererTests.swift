import Testing
import Foundation
@testable import TerminalUI

@Suite("LiveRenderer Tests")
struct LiveRendererTests {
    
    @Test("Basic render operation")
    func testBasicRender() async throws {
        let renderer = LiveRenderer()
        
        let view = Text("Hello, Live!")
            .foreground(.semantic(.accent))
        
        // This should not crash
        await renderer.render(view)
    }
    
    @Test("Clear screen operation")
    func testClearScreen() async throws {
        let renderer = LiveRenderer()
        
        // Render something first
        await renderer.render(Text("Initial content"))
        
        // Clear the screen
        await renderer.clear()
    }
    
    @Test("Update at specific position")
    func testUpdateAtPosition() async throws {
        let renderer = LiveRenderer()
        
        let position = Point(x: 10, y: 5)
        let view = HStack {
            Text("Status:")
            Text("OK").foreground(.semantic(.success))
        }
        
        await renderer.update(at: position, view: view)
    }
    
    @Test("Cursor management operations")
    func testCursorManagement() async throws {
        let renderer = LiveRenderer()
        
        // Save cursor position
        await renderer.saveCursor()
        
        // Move cursor
        await renderer.moveCursor(to: Point(x: 20, y: 10))
        
        // Render something
        await renderer.render(Text("Moved text"))
        
        // Restore cursor
        await renderer.restoreCursor()
    }
    
    @Test("Cursor visibility control")
    func testCursorVisibility() async throws {
        let renderer = LiveRenderer()
        
        // Hide cursor
        await renderer.hideCursor()
        
        // Render content
        await renderer.render(Text("Content without cursor"))
        
        // Show cursor again
        await renderer.showCursor()
    }
    
    @Test("Line clearing operations")
    func testLineClearingOperations() async throws {
        let renderer = LiveRenderer()
        
        // Clear current line
        await renderer.clearLine()
        
        // Clear to end of line
        await renderer.clearToEndOfLine()
    }
    
    @Test("Complex view rendering")
    func testComplexViewRendering() async throws {
        let renderer = LiveRenderer()
        
        let complexView = VStack {
            Text("Progress Report").bold()
            Divider()
            HStack {
                Text("Task 1:")
                ProgressView(value: 0.5, total: 1.0)
            }
            HStack {
                Text("Task 2:")
                Spinner.loading("Processing...")
            }
        }
        
        await renderer.render(complexView)
    }
    
    @Test("Streaming text update simulation")
    func testStreamingTextUpdate() async throws {
        let renderer = LiveRenderer()
        
        // Simulate streaming text updates
        var accumulatedText = ""
        let chunks = ["Hello", " ", "from", " ", "streaming", " ", "output!"]
        
        for chunk in chunks {
            accumulatedText += chunk
            
            let view = Panel(title: "Stream Output") {
                Text(accumulatedText)
            }.rounded()
            
            await renderer.clear()
            await renderer.render(view)
        }
    }
    
    @Test("Multiple position updates")
    func testMultiplePositionUpdates() async throws {
        let renderer = LiveRenderer()
        
        // Clear screen first
        await renderer.clear()
        
        // Update at different positions
        await renderer.update(
            at: Point(x: 0, y: 0),
            view: Text("Top-left corner")
        )
        
        await renderer.update(
            at: Point(x: 0, y: 5),
            view: Text("Middle area")
        )
        
        await renderer.update(
            at: Point(x: 0, y: 10),
            view: Text("Lower area")
        )
    }
    
    @Test("Flush operation")
    func testFlushOperation() async throws {
        let renderer = LiveRenderer()
        
        // Render some content
        await renderer.render(Text("Content to flush"))
        
        // Explicitly flush
        await renderer.flush()
    }
    
    @Test("Reset operation")
    func testResetOperation() async throws {
        let renderer = LiveRenderer()
        
        // Render some content
        await renderer.render(VStack {
            Text("Line 1")
            Text("Line 2")
            Text("Line 3")
        })
        
        // Reset everything
        await renderer.reset()
    }
    
    @Test("Point struct properties")
    func testPointStruct() async throws {
        let point = Point(x: 10, y: 20)
        #expect(point.x == 10)
        #expect(point.y == 20)
        
        let zero = Point.zero
        #expect(zero.x == 0)
        #expect(zero.y == 0)
        
        // Test Equatable
        let point2 = Point(x: 10, y: 20)
        #expect(point == point2)
        
        let point3 = Point(x: 5, y: 10)
        #expect(point != point3)
    }
}