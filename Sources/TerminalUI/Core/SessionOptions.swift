import Foundation

public struct SessionOptions: Sendable {

    public var collapseChildren: Bool
    

    public var liveFPS: Int
    

    public var headless: Bool
    

    public var theme: Theme
    

    public var enableMouse: Bool
    

    public var clearOnStart: Bool
    

    public var restoreCursorOnEnd: Bool
    

    public var bufferSize: Int
    

    public var debug: Bool
    
    public init(
        collapseChildren: Bool = true,
        liveFPS: Int = 15,
        headless: Bool = false,
        theme: Theme = .default,
        enableMouse: Bool = false,
        clearOnStart: Bool = false,
        restoreCursorOnEnd: Bool = true,
        bufferSize: Int = 1000,
        debug: Bool = false
    ) {
        self.collapseChildren = collapseChildren
        self.liveFPS = liveFPS
        self.headless = headless
        self.theme = theme
        self.enableMouse = enableMouse
        self.clearOnStart = clearOnStart
        self.restoreCursorOnEnd = restoreCursorOnEnd
        self.bufferSize = bufferSize
        self.debug = debug
    }
    

    public static let `default` = SessionOptions()
    

    public static let ci = SessionOptions(
        collapseChildren: false,
        liveFPS: 1,
        headless: false,
        enableMouse: false,
        clearOnStart: false
    )
    

    public static let headless = SessionOptions(
        headless: true,
        enableMouse: false,
        clearOnStart: false
    )
    

    public static let test = SessionOptions(
        liveFPS: 60,
        headless: true,
        bufferSize: 10000,
        debug: true
    )
}