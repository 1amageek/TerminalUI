import Foundation

public struct Meter: ConsoleView {
    private let value: Double
    private let min: Double
    private let max: Double
    private let label: String?
    private let unit: String?
    private let width: Int
    private let showValue: Bool
    private let segments: Int
    private let colors: MeterColors
    
    public struct MeterColors: Sendable {
        public let low: ANSIColor
        public let medium: ANSIColor
        public let high: ANSIColor
        public let critical: ANSIColor
        
        public init(
            low: ANSIColor = .semantic(.success),
            medium: ANSIColor = .semantic(.warning),
            high: ANSIColor = .semantic(.error),
            critical: ANSIColor = .rgb(255, 0, 0)
        ) {
            self.low = low
            self.medium = medium
            self.high = high
            self.critical = critical
        }
        
        public static let `default` = MeterColors()
        
        public static let temperature = MeterColors(
            low: .semantic(.info),
            medium: .semantic(.success),
            high: .semantic(.warning),
            critical: .semantic(.error)
        )
        
        public static let battery = MeterColors(
            low: .semantic(.error),
            medium: .semantic(.warning),
            high: .semantic(.success),
            critical: .semantic(.success)
        )
    }
    
    public init(
        value: Double,
        min: Double = 0,
        max: Double = 100,
        label: String? = nil,
        unit: String? = nil,
        width: Int = 20,
        showValue: Bool = true,
        segments: Int = 10,
        colors: MeterColors = .default
    ) {
        self.value = value
        self.min = min
        self.max = max
        self.label = label
        self.unit = unit
        self.width = width
        self.showValue = showValue
        self.segments = segments
        self.colors = colors
    }
    
    public func _makeNode(context: inout RenderContext) -> Node {
        let normalizedValue = (value - min) / (max - min)
        let clampedValue = Swift.min(Swift.max(normalizedValue, 0), 1)
        
        let properties = PropertyContainer()
            .with(.value, value: value)
            .with(.min, value: min)
            .with(.max, value: max)
            .with(.normalizedValue, value: clampedValue)
            .with(.label, value: label ?? "")
            .with(.unit, value: unit ?? "")
            .with(.width, value: width)
            .with(.showValue, value: showValue)
            .with(.segments, value: segments)
            .with(.colors, value: [
                "low": colors.low.toHex(),
                "medium": colors.medium.toHex(),
                "high": colors.high.toHex(),
                "critical": colors.critical.toHex()
            ])
        
        return Node(
            id: context.makeNodeID(),
            kind: .meter,
            properties: properties
        )
    }
}

public struct MeterRenderer {
    private let theme: Theme
    
    public init(theme: Theme = .default) {
        self.theme = theme
    }
    
    public func render(_ node: Node, at position: Point, width: Int) -> [RenderCommand] {
        var commands: [RenderCommand] = []
        
        let value = node.properties[.value] ?? 0
        let normalizedValue = node.properties[.normalizedValue] ?? 0
        let _ = node.properties[.width] ?? 20
        let segments = node.properties[.segments] ?? 10
        let showValue = node.properties[.showValue] ?? true
        let label = node.properties[.label] ?? ""
        let unit = node.properties[.unit] ?? ""
        
        var currentY = position.y
        

        if !label.isEmpty {
            commands.append(.moveCursor(row: currentY, column: position.x))
            commands.append(.write(label))
            if showValue {
                commands.append(.write(": "))
                commands.append(.setStyle(.bold))
                commands.append(.write(String(format: "%.1f", value)))
                if !unit.isEmpty {
                    commands.append(.write(" \(unit)"))
                }
                commands.append(.reset)
            }
            currentY += 1
        }
        

        commands.append(.moveCursor(row: currentY, column: position.x))
        

        let filledSegments = Int(Double(segments) * normalizedValue)
        

        let color = getColor(for: normalizedValue, colors: node.properties[.colors])
        

        commands.append(.write("["))
        

        if filledSegments > 0 {
            commands.append(.setForeground(color))
            for _ in 0..<filledSegments {

                let char = if normalizedValue > 0.9 {
                    "█"
                } else if normalizedValue > 0.7 {
                    "▓"
                } else if normalizedValue > 0.3 {
                    "▒"
                } else {
                    "░"
                }
                commands.append(.write(char))
            }
            commands.append(.reset)
        }
        

        let emptySegments = segments - filledSegments
        if emptySegments > 0 {
            commands.append(.setForeground(.semantic(.muted)))
            commands.append(.write(String(repeating: "·", count: emptySegments)))
            commands.append(.reset)
        }
        
        commands.append(.write("]"))
        

        if showValue && label.isEmpty {
            let percentage = Int(normalizedValue * 100)
            commands.append(.write(" "))
            commands.append(.setForeground(color))
            commands.append(.write("\(percentage)%"))
            commands.append(.reset)
        }
        
        return commands
    }
    
    private func getColor(for value: Double, colors: [String: String]?) -> ANSIColor {
        guard let colors = colors else {
            return .semantic(.accent)
        }
        
        let colorKey = if value > 0.9 {
            "critical"
        } else if value > 0.7 {
            "high"
        } else if value > 0.3 {
            "medium"
        } else {
            "low"
        }
        
        if let hex = colors[colorKey], let color = ANSIColor.fromHex(hex) {
            return color
        }
        
        return .semantic(.accent)
    }
}

public extension Meter {

    static func cpu(usage: Double) -> Meter {
        Meter(
            value: usage,
            label: "CPU",
            unit: "%",
            colors: .default
        )
    }
    

    static func memory(used: Double, total: Double) -> Meter {
        Meter(
            value: used,
            min: 0,
            max: total,
            label: "Memory",
            unit: "GB",
            colors: .default
        )
    }
    

    static func disk(used: Double, total: Double) -> Meter {
        Meter(
            value: used,
            min: 0,
            max: total,
            label: "Disk",
            unit: "GB",
            colors: MeterColors(
                low: .semantic(.success),
                medium: .semantic(.info),
                high: .semantic(.warning),
                critical: .semantic(.error)
            )
        )
    }
    

    static func battery(level: Double) -> Meter {
        Meter(
            value: level,
            label: "Battery",
            unit: "%",
            colors: .battery
        )
    }
    

    static func temperature(celsius: Double) -> Meter {
        Meter(
            value: celsius,
            min: 0,
            max: 100,
            label: "Temperature",
            unit: "°C",
            colors: .temperature
        )
    }
}