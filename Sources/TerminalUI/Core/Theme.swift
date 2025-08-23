import Foundation

public enum ANSIColor: Sendable, Hashable, Codable {

    case indexed(UInt8)
    

    case xterm256(UInt8)
    

    case rgb(UInt8, UInt8, UInt8)
    

    case semantic(SemanticColor)
    

    case none
    
    public enum SemanticColor: String, Sendable, CaseIterable, Codable {
        case accent
        case success
        case warning
        case error
        case info
        case muted
        case primary
        case secondary
        case background
        case foreground
    }
}

public struct Theme: Sendable {

    public var accent: ANSIColor
    

    public var success: ANSIColor
    

    public var warning: ANSIColor
    

    public var error: ANSIColor
    

    public var info: ANSIColor
    

    public var muted: ANSIColor
    

    public var primary: ANSIColor
    

    public var secondary: ANSIColor
    

    public var background: ANSIColor
    

    public var foreground: ANSIColor
    
    public init(
        accent: ANSIColor = .rgb(0, 122, 255),
        success: ANSIColor = .rgb(52, 199, 89),
        warning: ANSIColor = .rgb(255, 149, 0),
        error: ANSIColor = .rgb(255, 59, 48),
        info: ANSIColor = .rgb(90, 200, 250),
        muted: ANSIColor = .rgb(142, 142, 147),
        primary: ANSIColor = .rgb(255, 255, 255),
        secondary: ANSIColor = .rgb(174, 174, 178),
        background: ANSIColor = .none,
        foreground: ANSIColor = .none
    ) {
        self.accent = accent
        self.success = success
        self.warning = warning
        self.error = error
        self.info = info
        self.muted = muted
        self.primary = primary
        self.secondary = secondary
        self.background = background
        self.foreground = foreground
    }
    

    public static let `default` = Theme()
    

    public static let dark = Theme(
        accent: .rgb(10, 132, 255),
        success: .rgb(48, 209, 88),
        warning: .rgb(255, 159, 10),
        error: .rgb(255, 69, 58),
        info: .rgb(94, 210, 255),
        muted: .rgb(142, 142, 147),
        primary: .rgb(255, 255, 255),
        secondary: .rgb(174, 174, 178),
        background: .rgb(0, 0, 0),
        foreground: .rgb(255, 255, 255)
    )
    

    public static let light = Theme(
        accent: .rgb(0, 112, 245),
        success: .rgb(40, 180, 71),
        warning: .rgb(245, 139, 0),
        error: .rgb(245, 49, 38),
        info: .rgb(0, 180, 230),
        muted: .rgb(142, 142, 147),
        primary: .rgb(0, 0, 0),
        secondary: .rgb(86, 86, 92),
        background: .rgb(255, 255, 255),
        foreground: .rgb(0, 0, 0)
    )
    

    public func resolve(_ semantic: ANSIColor.SemanticColor) -> ANSIColor {
        switch semantic {
        case .accent: return accent
        case .success: return success
        case .warning: return warning
        case .error: return error
        case .info: return info
        case .muted: return muted
        case .primary: return primary
        case .secondary: return secondary
        case .background: return background
        case .foreground: return foreground
        }
    }
    

    public func resolve(_ color: ANSIColor) -> ANSIColor {
        switch color {
        case .semantic(let semantic):
            return resolve(semantic)
        default:
            return color
        }
    }
}

public extension ANSIColor {

    func toANSI(capabilities: Capabilities, isForeground: Bool = true) -> String {
        switch self {
        case .none:
            return ""
            
        case .indexed(let index) where index < 16:

            let base = isForeground ? 30 : 40
            if index < 8 {
                return "\u{001B}[\(base + Int(index))m"
            } else {
                return "\u{001B}[\(base + 60 + Int(index) - 8)m"
            }
            
        case .indexed(let index), .xterm256(let index):

            if capabilities.xterm256 {
                return "\u{001B}[\(isForeground ? 38 : 48);5;\(index)m"
            } else {

                let fallback = index < 16 ? index : nearestBasicColor(from: index)
                return ANSIColor.indexed(fallback).toANSI(capabilities: capabilities, isForeground: isForeground)
            }
            
        case .rgb(let r, let g, let b):

            if capabilities.trueColor {
                return "\u{001B}[\(isForeground ? 38 : 48);2;\(r);\(g);\(b)m"
            } else if capabilities.xterm256 {

                let index = nearestXterm256Color(r: r, g: g, b: b)
                return "\u{001B}[\(isForeground ? 38 : 48);5;\(index)m"
            } else {

                let index = nearestBasicColorFromRGB(r: r, g: g, b: b)
                return ANSIColor.indexed(index).toANSI(capabilities: capabilities, isForeground: isForeground)
            }
            
        case .semantic:

            return ""
        }
    }
    

    private func nearestBasicColor(from index: UInt8) -> UInt8 {

        switch index {
        case 0...15: return index
        case 16...231:

            let adjusted = Int(index) - 16
            let r = (adjusted / 36) * 51
            let g = ((adjusted % 36) / 6) * 51
            let b = (adjusted % 6) * 51
            return nearestBasicColorFromRGB(r: UInt8(r), g: UInt8(g), b: UInt8(b))
        default:

            let gray = Int(index) - 232
            return gray < 12 ? 0 : 15
        }
    }
    

    private func nearestBasicColorFromRGB(r: UInt8, g: UInt8, b: UInt8) -> UInt8 {

        let brightness = (Int(r) + Int(g) + Int(b)) / 3
        
        if brightness < 64 {
            return 0
        } else if brightness > 192 {
            return 15
        } else if r > g && r > b {
            return brightness > 128 ? 9 : 1
        } else if g > r && g > b {
            return brightness > 128 ? 10 : 2
        } else if b > r && b > g {
            return brightness > 128 ? 12 : 4
        } else {
            return 8
        }
    }
    

    private func nearestXterm256Color(r: UInt8, g: UInt8, b: UInt8) -> UInt8 {

        if r == g && g == b {
            if r < 8 {
                return 16
            } else if r > 248 {
                return 231
            } else {

                let gray = (Int(r) - 8) / 10
                return UInt8(232 + gray)
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
}