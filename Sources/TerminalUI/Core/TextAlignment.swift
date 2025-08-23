import Foundation

public enum TextAlignment: String, Sendable, CaseIterable {
    case leading
    case center
    case trailing
    case left
    case right
    case justified
    

    public var horizontalAlignment: HorizontalAlignment {
        switch self {
        case .leading, .left:
            return .leading
        case .center:
            return .center
        case .trailing, .right, .justified:
            return .trailing
        }
    }
}

public enum HorizontalAlignment: String, Sendable, CaseIterable {
    case leading
    case center
    case trailing
}

public enum VerticalAlignment: String, Sendable, CaseIterable {
    case top
    case center
    case bottom
}