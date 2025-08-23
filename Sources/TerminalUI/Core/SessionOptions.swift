import Foundation

public struct SessionOptions: Sendable {
    public var liveFPS: Int
    public var theme: Theme
    public var debug: Bool
    public var headless: Bool
    
    public init(
        liveFPS: Int = 15,
        theme: Theme = .default,
        debug: Bool = false,
        headless: Bool = false
    ) {
        self.liveFPS = liveFPS
        self.theme = theme
        self.debug = debug
        self.headless = headless
    }
    

    public static let `default` = SessionOptions()
    

    public static let ci = SessionOptions(
        liveFPS: 1,
        headless: false
    )
    

    public static let headless = SessionOptions(
        headless: true
    )
    

    public static let test = SessionOptions(
        liveFPS: 60,
        debug: true,
        headless: true
    )
}