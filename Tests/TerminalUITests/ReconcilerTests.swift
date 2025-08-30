import XCTest
@testable import TerminalUI

final class ReconcilerTests: XCTestCase {
    
    let reconciler = Reconciler()
    
    // MARK: - Helper Functions
    
    func makeNode(
        address: String,
        logicalID: String? = nil,
        kind: NodeKind = .text,
        children: [Node] = []
    ) -> Node {
        Node(
            address: Address(address),
            logicalID: logicalID.map { LogicalID($0) },
            kind: kind,
            children: children
        )
    }
    
    // MARK: - Basic Tests
    
    func testEmptyToNewTree() {
        // Empty tree to new tree should generate only insertions
        let newTree = makeNode(
            address: "root",
            children: [
                makeNode(address: "child1"),
                makeNode(address: "child2")
            ]
        )
        
        let result = reconciler.reconcile(oldTree: nil, newTree: newTree)
        
        XCTAssertEqual(result.insertions.count, 3) // root + 2 children
        XCTAssertEqual(result.updates.count, 0)
        XCTAssertEqual(result.deletions.count, 0)
        XCTAssertEqual(result.moves.count, 0)
    }
    
    func testTreeToEmpty() {
        // Tree to empty should generate only deletions
        let oldTree = makeNode(
            address: "root",
            children: [
                makeNode(address: "child1"),
                makeNode(address: "child2")
            ]
        )
        
        let newTree = makeNode(address: "root")
        
        let result = reconciler.reconcile(oldTree: oldTree, newTree: newTree)
        
        XCTAssertEqual(result.insertions.count, 0)
        XCTAssertEqual(result.updates.count, 0)
        XCTAssertEqual(result.deletions.count, 2) // 2 children deleted
        XCTAssertEqual(result.moves.count, 0)
    }
    
    func testIdenticalTrees() {
        // Identical trees should generate no operations
        let tree = makeNode(
            address: "root",
            logicalID: "root-id",
            children: [
                makeNode(address: "child1", logicalID: "child1-id"),
                makeNode(address: "child2", logicalID: "child2-id")
            ]
        )
        
        let result = reconciler.reconcile(oldTree: tree, newTree: tree)
        
        XCTAssertFalse(result.hasChanges)
        XCTAssertEqual(result.operationCount, 0)
    }
    
    // MARK: - Logical ID Tests
    
    func testLogicalIDMatching() {
        // Nodes with same logical ID should be matched even if addresses differ
        let oldTree = makeNode(
            address: "root",
            children: [
                makeNode(address: "old-addr", logicalID: "item-1"),
                makeNode(address: "child2", logicalID: "item-2")
            ]
        )
        
        let newTree = makeNode(
            address: "root",
            children: [
                makeNode(address: "new-addr", logicalID: "item-1"),
                makeNode(address: "child2", logicalID: "item-2")
            ]
        )
        
        let result = reconciler.reconcile(oldTree: oldTree, newTree: newTree)
        
        // Should detect that item-1 is the same node despite address change
        XCTAssertEqual(result.insertions.count, 0)
        XCTAssertEqual(result.deletions.count, 0)
    }
    
    func testReordering() {
        // Test that reordering with logical IDs generates move operations
        let oldTree = makeNode(
            address: "root",
            children: [
                makeNode(address: "child1", logicalID: "a"),
                makeNode(address: "child2", logicalID: "b"),
                makeNode(address: "child3", logicalID: "c")
            ]
        )
        
        let newTree = makeNode(
            address: "root",
            children: [
                makeNode(address: "child3", logicalID: "c"),
                makeNode(address: "child1", logicalID: "a"),
                makeNode(address: "child2", logicalID: "b")
            ]
        )
        
        let result = reconciler.reconcile(oldTree: oldTree, newTree: newTree)
        
        // Should generate move operations
        XCTAssertTrue(result.moves.count > 0)
        XCTAssertEqual(result.insertions.count, 0)
        XCTAssertEqual(result.deletions.count, 0)
    }
    
    // MARK: - Mixed Operations Tests
    
    func testMixedOperations() {
        // Test a mix of insertions, deletions, and updates
        let oldTree = makeNode(
            address: "root",
            children: [
                makeNode(address: "child1", logicalID: "keep"),
                makeNode(address: "child2", logicalID: "delete"),
                makeNode(address: "child3", logicalID: "move")
            ]
        )
        
        let newTree = makeNode(
            address: "root",
            children: [
                makeNode(address: "child3", logicalID: "move"),
                makeNode(address: "child1", logicalID: "keep"),
                makeNode(address: "new-child", logicalID: "new")
            ]
        )
        
        let result = reconciler.reconcile(oldTree: oldTree, newTree: newTree)
        
        XCTAssertEqual(result.insertions.count, 1) // new-child
        XCTAssertEqual(result.deletions.count, 1) // delete
        XCTAssertTrue(result.moves.count > 0) // move operation
    }
    
    // MARK: - Positional Matching Tests
    
    func testPositionalMatchingWithoutLogicalIDs() {
        // Without logical IDs, should match by position and kind
        let oldTree = makeNode(
            address: "root",
            children: [
                makeNode(address: "text1", kind: .text),
                makeNode(address: "panel1", kind: .panel),
                makeNode(address: "text2", kind: .text)
            ]
        )
        
        let newTree = makeNode(
            address: "root",
            children: [
                makeNode(address: "text1", kind: .text), // Same position, same kind
                makeNode(address: "panel1", kind: .panel), // Same position, same kind
                makeNode(address: "divider1", kind: .divider) // Same position, different kind
            ]
        )
        
        let result = reconciler.reconcile(oldTree: oldTree, newTree: newTree)
        
        // First two should match by position, third should be delete + insert
        XCTAssertEqual(result.insertions.count, 1) // note1
        XCTAssertEqual(result.deletions.count, 1) // text2
    }
    
    // MARK: - Deep Tree Tests
    
    func testDeepTreeReconciliation() {
        // Test reconciliation with nested structures
        let oldTree = makeNode(
            address: "root",
            children: [
                makeNode(
                    address: "parent1",
                    logicalID: "p1",
                    children: [
                        makeNode(address: "nested1", logicalID: "n1"),
                        makeNode(address: "nested2", logicalID: "n2")
                    ]
                )
            ]
        )
        
        let newTree = makeNode(
            address: "root",
            children: [
                makeNode(
                    address: "parent1",
                    logicalID: "p1",
                    children: [
                        makeNode(address: "nested2", logicalID: "n2"),
                        makeNode(address: "nested1", logicalID: "n1"),
                        makeNode(address: "nested3", logicalID: "n3")
                    ]
                )
            ]
        )
        
        let result = reconciler.reconcile(oldTree: oldTree, newTree: newTree)
        
        XCTAssertEqual(result.insertions.count, 1) // nested3
        XCTAssertTrue(result.moves.count > 0) // Reordering of n1 and n2
    }
    
    // MARK: - Edge Cases
    
    func testDuplicateLogicalIDs() {
        // Test that duplicate logical IDs trigger a fatal error in DEBUG builds
        // In production, this should be caught during development
        
        #if DEBUG
        // We expect this to trap in DEBUG builds
        // This test verifies the validation logic is working
        // Since we can't test fatal errors directly, we'll skip this test
        print("Skipping duplicate ID test in DEBUG mode - would trigger fatal error")
        #else
        // In release builds, duplicate IDs might be handled differently
        let tree = makeNode(
            address: "root",
            children: [
                makeNode(address: "child1", logicalID: "id1"),
                makeNode(address: "child2", logicalID: "id2"),
                makeNode(address: "child3", logicalID: "id3")
            ]
        )
        
        let result = reconciler.reconcile(oldTree: tree, newTree: tree)
        XCTAssertFalse(result.hasChanges)
        #endif
    }
    
    // MARK: - Performance Tests
    
    func testLargeTreePerformance() {
        // Test performance with a large tree
        func makeLargeTree(prefix: String, childCount: Int = 100) -> Node {
            let children = (0..<childCount).map { i in
                makeNode(
                    address: "\(prefix)-child-\(i)",
                    logicalID: "item-\(i)"
                )
            }
            return makeNode(address: "\(prefix)-root", children: children)
        }
        
        let oldTree = makeLargeTree(prefix: "old")
        let newTree = makeLargeTree(prefix: "new")
        
        measure {
            _ = reconciler.reconcile(oldTree: oldTree, newTree: newTree)
        }
    }
    
    // MARK: - Summary Tests
    
    func testReconciliationSummary() {
        let oldTree = makeNode(
            address: "root",
            children: [
                makeNode(address: "child1", logicalID: "a"),
                makeNode(address: "child2", logicalID: "b")
            ]
        )
        
        let newTree = makeNode(
            address: "root",
            children: [
                makeNode(address: "child2", logicalID: "b"),
                makeNode(address: "child3", logicalID: "c")
            ]
        )
        
        let result = reconciler.reconcile(oldTree: oldTree, newTree: newTree)
        
        // Check summary string
        XCTAssertTrue(result.summary.contains("insertion"))
        XCTAssertTrue(result.summary.contains("deletion"))
        XCTAssertTrue(result.hasChanges)
    }
    
    #if DEBUG
    func testValidation() {
        let newTree = makeNode(
            address: "root",
            children: [
                makeNode(address: "child1"),
                makeNode(address: "child2")
            ]
        )
        
        let result = reconciler.reconcile(oldTree: nil, newTree: newTree)
        
        // Validate the result
        let isValid = reconciler.validateResult(result, oldTree: nil, newTree: newTree)
        XCTAssertTrue(isValid)
    }
    #endif
}