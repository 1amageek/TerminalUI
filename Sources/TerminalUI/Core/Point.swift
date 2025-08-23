import Foundation

public struct Point: Sendable, Equatable {
    public let x: Int
    public let y: Int
    
    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
    
    public static let zero = Point(x: 0, y: 0)
    

    public func offset(dx: Int = 0, dy: Int = 0) -> Point {
        Point(x: x + dx, y: y + dy)
    }
    

    public func withX(_ newX: Int) -> Point {
        Point(x: newX, y: y)
    }
    

    public func withY(_ newY: Int) -> Point {
        Point(x: x, y: newY)
    }
}