import Testing
import Foundation
@testable import TerminalUI

@Suite("LiveSession Tests")
struct LiveSessionTests {
    
    @Test("Add and update single element")
    func testAddAndUpdateSingleElement() async throws {
        let session = LiveSession()
        
        // Add initial element
        await session.update("task-1", with: Text("Initial task"))
        
        let ids = await session.getAllIDs()
        #expect(ids.contains("task-1"))
        #expect(await session.count == 1)
        
        // Update the element
        await session.update("task-1", with: Text("Updated task"))
        
        // Count should remain the same
        #expect(await session.count == 1)
    }
    
    @Test("Multiple elements management")
    func testMultipleElementsManagement() async throws {
        let session = LiveSession()
        
        // Add multiple elements
        await session.update("element-1", with: Text("First"))
        await session.update("element-2", with: Text("Second"))
        await session.update("element-3", with: Text("Third"))
        
        let ids = await session.getAllIDs()
        #expect(ids.count == 3)
        #expect(ids.contains("element-1"))
        #expect(ids.contains("element-2"))
        #expect(ids.contains("element-3"))
        #expect(await session.count == 3)
    }
    
    @Test("Remove element")
    func testRemoveElement() async throws {
        let session = LiveSession()
        
        // Add elements
        await session.update("keep", with: Text("Keep this"))
        await session.update("remove", with: Text("Remove this"))
        
        #expect(await session.count == 2)
        
        // Remove one element
        await session.remove("remove")
        
        #expect(await session.count == 1)
        let ids = await session.getAllIDs()
        #expect(ids.contains("keep"))
        #expect(!ids.contains("remove"))
    }
    
    @Test("Clear all elements")
    func testClearAllElements() async throws {
        let session = LiveSession()
        
        // Add multiple elements
        await session.update("1", with: Text("One"))
        await session.update("2", with: Text("Two"))
        await session.update("3", with: Text("Three"))
        
        #expect(await session.count == 3)
        
        // Clear all
        await session.clear()
        
        #expect(await session.count == 0)
        let ids = await session.getAllIDs()
        #expect(ids.isEmpty)
    }
    
    @Test("Position management")
    func testPositionManagement() async throws {
        let session = LiveSession()
        
        let position = Point(x: 10, y: 5)
        await session.update("positioned", at: position, with: Text("Positioned text"))
        
        let retrievedPosition = await session.getPosition("positioned")
        #expect(retrievedPosition == position)
    }
    
    @Test("Move element to new position")
    func testMoveElement() async throws {
        let session = LiveSession()
        
        let initialPosition = Point(x: 0, y: 0)
        await session.update("movable", at: initialPosition, with: Text("Movable"))
        
        let newPosition = Point(x: 20, y: 10)
        await session.move("movable", to: newPosition)
        
        let retrievedPosition = await session.getPosition("movable")
        #expect(retrievedPosition == newPosition)
    }
    
    @Test("Get view from session")
    func testGetView() async throws {
        let session = LiveSession()
        
        let text = Text("Stored view")
        await session.update("stored", with: text)
        
        let retrievedView = await session.getView("stored")
        #expect(retrievedView != nil)
    }
    
    @Test("Redraw all elements")
    func testRedrawAll() async throws {
        let session = LiveSession()
        
        // Add multiple elements at different positions
        await session.update("top", at: Point(x: 0, y: 0), with: Text("Top"))
        await session.update("middle", at: Point(x: 0, y: 5), with: Text("Middle"))
        await session.update("bottom", at: Point(x: 0, y: 10), with: Text("Bottom"))
        
        // This should not crash
        await session.redrawAll()
    }
    
    @Test("Complex views in session")
    func testComplexViewsInSession() async throws {
        let session = LiveSession()
        
        // Add complex view 1: Progress
        await session.update("progress", at: Point(x: 0, y: 0), with: VStack {
            Text("Download Progress")
            ProgressView(value: 0.3, total: 1.0)
        })
        
        // Add complex view 2: Status panel
        await session.update("status", at: Point(x: 0, y: 5), with: Panel(title: "Status") {
            HStack {
                Text("Status:")
                Text("Active").foreground(.semantic(.success)).bold()
            }
        })
        
        // Add complex view 3: List
        await session.update("list", at: Point(x: 0, y: 10), with: VStack {
            Text("Tasks:")
            ForEach(["Task 1", "Task 2", "Task 3"]) { task in
                Text("• \(task)")
            }
        })
        
        #expect(await session.count == 3)
    }
    
    @Test("Update element with differential rendering")
    func testDifferentialUpdate() async throws {
        let session = LiveSession()
        
        // Initial complex view
        await session.update("diff-test", with: VStack {
            Text("Title")
            Text("Subtitle")
            ProgressView(value: 0.0, total: 1.0)
        })
        
        // Update with changes
        await session.update("diff-test", with: VStack {
            Text("Title")  // Same
            Text("Updated Subtitle")  // Changed
            ProgressView(value: 0.5, total: 1.0)  // Changed value
        })
        
        // Should still be one element
        #expect(await session.count == 1)
    }
    
    @Test("Auto-positioning for elements")
    func testAutoPositioning() async throws {
        let session = LiveSession()
        
        // Add elements without explicit positions
        await session.update("auto-1", with: Text("Auto 1"))
        await session.update("auto-2", with: Text("Auto 2"))
        await session.update("auto-3", with: Text("Auto 3"))
        
        // Check that positions were assigned
        let pos1 = await session.getPosition("auto-1")
        let pos2 = await session.getPosition("auto-2")
        let pos3 = await session.getPosition("auto-3")
        
        #expect(pos1 != nil)
        #expect(pos2 != nil)
        #expect(pos3 != nil)
        
        // Positions should be different
        #expect(pos1 != pos2)
        #expect(pos2 != pos3)
        #expect(pos1 != pos3)
    }
    
    @Test("Build process simulation")
    func testBuildProcessSimulation() async throws {
        let session = LiveSession()
        
        // Simulate multiple build tasks
        let tasks = [
            ("compile-main", "Compiling main.swift"),
            ("compile-utils", "Compiling utils.swift"),
            ("compile-tests", "Compiling tests.swift")
        ]
        
        // Start all tasks
        for (id, description) in tasks {
            await session.update(id, with: HStack {
                Spinner.loading()
                Text(description)
            })
        }
        
        #expect(await session.count == 3)
        
        // Complete first task
        await session.update("compile-main", with: HStack {
            Text("✅")
            Text("main.swift compiled")
        })
        
        // Complete second task
        await session.update("compile-utils", with: HStack {
            Text("✅")
            Text("utils.swift compiled")
        })
        
        // Fail third task
        await session.update("compile-tests", with: HStack {
            Text("❌")
            Text("tests.swift failed").foreground(.semantic(.error))
        })
        
        #expect(await session.count == 3)
    }
    
    @Test("Streaming output simulation")
    func testStreamingOutputSimulation() async throws {
        let session = LiveSession()
        
        var output = ""
        let lines = [
            "Starting process...",
            "Connecting to server...",
            "Downloading data...",
            "Processing...",
            "Complete!"
        ]
        
        for line in lines {
            output += line + "\n"
            
            await session.update("stream", with: Panel(title: "Output") {
                VStack {
                    Text(output)
                }
            }.rounded())
        }
        
        #expect(await session.count == 1)
    }
}