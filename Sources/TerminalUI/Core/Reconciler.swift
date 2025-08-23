import Foundation

/// Reconciler for efficient tree diffing and updates
/// Prioritizes logical IDs for matching, falls back to positional matching
public struct Reconciler: Sendable {
    
    /// Result of reconciliation between old and new trees
    public struct ReconciliationResult: Sendable {
        public let insertions: [NodeOperation]
        public let updates: [NodeOperation]
        public let deletions: [NodeOperation]
        public let moves: [NodeOperation]
    }
    
    /// Represents an operation on a node
    public struct NodeOperation: Sendable {
        public enum OperationType: Sendable {
            case insert
            case update
            case delete
            case move(from: Address, to: Address)
        }
        
        public let type: OperationType
        public let node: Node
        public let path: [Address] // Path from root to this node
    }
    
    /// Perform reconciliation between old and new node trees
    public func reconcile(oldTree: Node?, newTree: Node) -> ReconciliationResult {
        var insertions: [NodeOperation] = []
        var updates: [NodeOperation] = []
        var deletions: [NodeOperation] = []
        var moves: [NodeOperation] = []
        
        // If no old tree, everything is an insertion
        guard let oldTree = oldTree else {
            collectInsertions(newTree, path: [], into: &insertions)
            return ReconciliationResult(
                insertions: insertions,
                updates: updates,
                deletions: deletions,
                moves: moves
            )
        }
        
        // Perform recursive diff
        diffNodes(
            old: oldTree,
            new: newTree,
            path: [],
            insertions: &insertions,
            updates: &updates,
            deletions: &deletions,
            moves: &moves
        )
        
        return ReconciliationResult(
            insertions: insertions,
            updates: updates,
            deletions: deletions,
            moves: moves
        )
    }
    
    private func diffNodes(
        old: Node,
        new: Node,
        path: [Address],
        insertions: inout [NodeOperation],
        updates: inout [NodeOperation],
        deletions: inout [NodeOperation],
        moves: inout [NodeOperation]
    ) {
        // Check if nodes are the same (by logical ID or address)
        let isSameNode = areNodesSame(old: old, new: new)
        
        if isSameNode {
            // Check if properties changed
            if old.properties != new.properties || old.kind != new.kind {
                updates.append(NodeOperation(
                    type: .update,
                    node: new,
                    path: path
                ))
            }
            
            // Diff children
            diffChildren(
                oldChildren: old.children,
                newChildren: new.children,
                parentPath: path + [new.address],
                insertions: &insertions,
                updates: &updates,
                deletions: &deletions,
                moves: &moves
            )
        } else {
            // Different nodes - delete old, insert new
            deletions.append(NodeOperation(
                type: .delete,
                node: old,
                path: path
            ))
            insertions.append(NodeOperation(
                type: .insert,
                node: new,
                path: path
            ))
        }
    }
    
    private func diffChildren(
        oldChildren: [Node],
        newChildren: [Node],
        parentPath: [Address],
        insertions: inout [NodeOperation],
        updates: inout [NodeOperation],
        deletions: inout [NodeOperation],
        moves: inout [NodeOperation]
    ) {
        // Build maps for efficient lookup
        let oldByLogicalID = Dictionary(
            oldChildren.compactMap { node in
                node.logicalID.map { ($0, node) }
            },
            uniquingKeysWith: { first, _ in first }
        )
        
        // Not currently used but kept for future optimizations
        _ = Dictionary(
            newChildren.compactMap { node in
                node.logicalID.map { ($0, node) }
            },
            uniquingKeysWith: { first, _ in first }
        )
        
        // Track which nodes have been processed
        var processedOldIndices = Set<Int>()
        var processedNewIndices = Set<Int>()
        
        // Phase 1: Match by logical ID
        for (newIndex, newNode) in newChildren.enumerated() {
            if let logicalID = newNode.logicalID,
               let oldNode = oldByLogicalID[logicalID],
               let oldIndex = oldChildren.firstIndex(where: { $0.logicalID == logicalID }) {
                
                processedOldIndices.insert(oldIndex)
                processedNewIndices.insert(newIndex)
                
                // Check if node moved
                if oldIndex != newIndex {
                    moves.append(NodeOperation(
                        type: .move(from: oldNode.address, to: newNode.address),
                        node: newNode,
                        path: parentPath
                    ))
                }
                
                // Recursively diff the matched nodes
                diffNodes(
                    old: oldNode,
                    new: newNode,
                    path: parentPath,
                    insertions: &insertions,
                    updates: &updates,
                    deletions: &deletions,
                    moves: &moves
                )
            }
        }
        
        // Phase 2: Match remaining nodes by position
        for (newIndex, newNode) in newChildren.enumerated() {
            guard !processedNewIndices.contains(newIndex) else { continue }
            
            // Try to find an unprocessed old node at the same position
            if newIndex < oldChildren.count,
               !processedOldIndices.contains(newIndex) {
                let oldNode = oldChildren[newIndex]
                
                // Only match if they're the same kind and neither has a logical ID
                if oldNode.kind == newNode.kind &&
                   oldNode.logicalID == nil &&
                   newNode.logicalID == nil {
                    
                    processedOldIndices.insert(newIndex)
                    processedNewIndices.insert(newIndex)
                    
                    diffNodes(
                        old: oldNode,
                        new: newNode,
                        path: parentPath,
                        insertions: &insertions,
                        updates: &updates,
                        deletions: &deletions,
                        moves: &moves
                    )
                }
            }
        }
        
        // Phase 3: Remaining new nodes are insertions
        for (newIndex, newNode) in newChildren.enumerated() {
            if !processedNewIndices.contains(newIndex) {
                collectInsertions(newNode, path: parentPath, into: &insertions)
            }
        }
        
        // Phase 4: Remaining old nodes are deletions
        for (oldIndex, oldNode) in oldChildren.enumerated() {
            if !processedOldIndices.contains(oldIndex) {
                collectDeletions(oldNode, path: parentPath, into: &deletions)
            }
        }
    }
    
    private func areNodesSame(old: Node, new: Node) -> Bool {
        // Priority 1: Check logical IDs if both exist
        if let oldID = old.logicalID, let newID = new.logicalID {
            return oldID == newID
        }
        
        // Priority 2: Check if addresses match and kinds match
        return old.address == new.address && old.kind == new.kind
    }
    
    private func collectInsertions(_ node: Node, path: [Address], into insertions: inout [NodeOperation]) {
        insertions.append(NodeOperation(
            type: .insert,
            node: node,
            path: path
        ))
        
        // Recursively collect insertions for children
        let childPath = path + [node.address]
        for child in node.children {
            collectInsertions(child, path: childPath, into: &insertions)
        }
    }
    
    private func collectDeletions(_ node: Node, path: [Address], into deletions: inout [NodeOperation]) {
        // Recursively collect deletions for children first (bottom-up)
        let childPath = path + [node.address]
        for child in node.children {
            collectDeletions(child, path: childPath, into: &deletions)
        }
        
        deletions.append(NodeOperation(
            type: .delete,
            node: node,
            path: path
        ))
    }
}

// MARK: - Reconciliation Extensions

extension Reconciler.ReconciliationResult {
    /// Check if there are any changes
    public var hasChanges: Bool {
        !insertions.isEmpty || !updates.isEmpty || !deletions.isEmpty || !moves.isEmpty
    }
    
    /// Total number of operations
    public var operationCount: Int {
        insertions.count + updates.count + deletions.count + moves.count
    }
    
    /// Get a summary description
    public var summary: String {
        var parts: [String] = []
        if !insertions.isEmpty {
            parts.append("\(insertions.count) insertions")
        }
        if !updates.isEmpty {
            parts.append("\(updates.count) updates")
        }
        if !deletions.isEmpty {
            parts.append("\(deletions.count) deletions")
        }
        if !moves.isEmpty {
            parts.append("\(moves.count) moves")
        }
        return parts.isEmpty ? "No changes" : parts.joined(separator: ", ")
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension Reconciler {
    /// Validate that a reconciliation result is valid
    public func validateResult(_ result: ReconciliationResult, oldTree: Node?, newTree: Node) -> Bool {
        // Ensure no duplicate operations on the same node
        var seenAddresses = Set<Address>()
        
        for op in result.insertions {
            if seenAddresses.contains(op.node.address) {
                print("Warning: Duplicate insertion for address \(op.node.address)")
                return false
            }
            seenAddresses.insert(op.node.address)
        }
        
        // Validate that moves have valid from/to addresses
        for op in result.moves {
            if case .move(let from, let to) = op.type {
                if from == to {
                    print("Warning: Move operation with same from/to address: \(from)")
                    return false
                }
            }
        }
        
        return true
    }
    
    /// Print a visual representation of the reconciliation
    public func printReconciliation(_ result: ReconciliationResult) {
        print("=== Reconciliation Result ===")
        print(result.summary)
        
        if !result.insertions.isEmpty {
            print("\nInsertions:")
            for op in result.insertions {
                print("  + \(op.node.address) (\(op.node.kind))")
            }
        }
        
        if !result.updates.isEmpty {
            print("\nUpdates:")
            for op in result.updates {
                print("  ~ \(op.node.address) (\(op.node.kind))")
            }
        }
        
        if !result.moves.isEmpty {
            print("\nMoves:")
            for op in result.moves {
                if case .move(let from, let to) = op.type {
                    print("  → \(from) to \(to)")
                }
            }
        }
        
        if !result.deletions.isEmpty {
            print("\nDeletions:")
            for op in result.deletions {
                print("  - \(op.node.address) (\(op.node.kind))")
            }
        }
    }
}
#endif