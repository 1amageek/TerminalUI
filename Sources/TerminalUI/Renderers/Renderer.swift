import Foundation

public protocol Renderer: Sendable {

    func apply(_ commands: [RenderCommand]) async throws
    

    func capabilities() -> Capabilities
    

    func flush() async throws
    

    func reset() async throws
}

public struct RendererBase {

    public static func convertColor(_ color: ANSIColor, capabilities: Capabilities, theme: Theme) -> ANSIColor {

        let resolved = theme.resolve(color)
        

        switch resolved {
        case .rgb(let r, let g, let b):
            if !capabilities.trueColor {
                if capabilities.xterm256 {

                    return .xterm256(nearestXterm256(r: r, g: g, b: b))
                } else {

                    return .indexed(nearest16Color(r: r, g: g, b: b))
                }
            }
        case .xterm256(let index):
            if !capabilities.xterm256 {

                return .indexed(index < 16 ? index : nearest16ColorFromIndex(index))
            }
        default:
            break
        }
        
        return resolved
    }
    

    private static func nearestXterm256(r: UInt8, g: UInt8, b: UInt8) -> UInt8 {

        if r == g && g == b {
            if r < 8 {
                return 16
            } else if r > 248 {
                return 231
            } else {
                let gray = (Int(r) - 8) / 10
                return UInt8(232 + min(23, gray))
            }
        }
        

        let levels: [UInt8] = [0, 95, 135, 175, 215, 255]
        
        func nearestLevel(_ value: UInt8) -> Int {
            var minDist = 256
            var nearest = 0
            for (i, level) in levels.enumerated() {
                let dist = abs(Int(value) - Int(level))
                if dist < minDist {
                    minDist = dist
                    nearest = i
                }
            }
            return nearest
        }
        
        let ri = nearestLevel(r)
        let gi = nearestLevel(g)
        let bi = nearestLevel(b)
        
        return UInt8(16 + (ri * 36) + (gi * 6) + bi)
    }
    

    private static func nearest16Color(r: UInt8, g: UInt8, b: UInt8) -> UInt8 {
        let brightness = (Int(r) + Int(g) + Int(b)) / 3
        
        if brightness < 64 {
            return 0
        } else if brightness > 192 {
            return 15
        } else {

            if r > g && r > b {
                return brightness > 128 ? 9 : 1
            } else if g > r && g > b {
                return brightness > 128 ? 10 : 2
            } else if b > r && b > g {
                return brightness > 128 ? 12 : 4
            } else if r > b {
                return brightness > 128 ? 11 : 3
            } else if b > r {
                return brightness > 128 ? 13 : 5
            } else if r > 0 && g > 0 {
                return brightness > 128 ? 14 : 6
            } else {
                return brightness > 128 ? 7 : 8
            }
        }
    }
    

    private static func nearest16ColorFromIndex(_ index: UInt8) -> UInt8 {
        switch index {
        case 0...15:
            return index
        case 16...231:

            let adjusted = Int(index) - 16
            let r = (adjusted / 36) * 51
            let g = ((adjusted % 36) / 6) * 51
            let b = (adjusted % 6) * 51
            return nearest16Color(r: UInt8(r), g: UInt8(g), b: UInt8(b))
        default:

            let gray = Int(index) - 232
            return gray < 12 ? 0 : 15
        }
    }
}

public enum RendererError: Error, LocalizedError {
    case notConnected
    case writeFailed(String)
    case invalidState(String)
    case unsupportedOperation(String)
    
    public var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Renderer is not connected to output"
        case .writeFailed(let message):
            return "Write failed: \(message)"
        case .invalidState(let message):
            return "Invalid renderer state: \(message)"
        case .unsupportedOperation(let message):
            return "Unsupported operation: \(message)"
        }
    }
}