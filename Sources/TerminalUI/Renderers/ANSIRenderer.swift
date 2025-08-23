import Foundation
import Synchronization

public final class ANSIRenderer: Renderer {
    private let output: FileHandle
    private let capabilitiesValue: Capabilities
    private let theme: Theme
    private let buffer: Mutex<String>
    private let bufferSize: Int
    

    private let state: Mutex<RenderState>
    
    private struct RenderState {
        var currentForeground: ANSIColor?
        var currentBackground: ANSIColor?
        var currentStyle: TextStyle = .none
        var cursorRow: Int = 0
        var cursorColumn: Int = 0
        var savedRow: Int = 0
        var savedColumn: Int = 0
    }
    
    public init(
        output: FileHandle = .standardOutput,
        capabilities: Capabilities? = nil,
        theme: Theme = .default,
        bufferSize: Int = 4096
    ) {
        self.output = output
        self.capabilitiesValue = capabilities ?? Capabilities.detect()
        self.theme = theme
        self.buffer = Mutex("")
        self.bufferSize = bufferSize
        self.state = Mutex(RenderState())
    }
    
    public func apply(_ commands: [RenderCommand]) async throws {
        for command in commands {
            try await applyCommand(command)
        }
    }
    
    private func applyCommand(_ command: RenderCommand) async throws {
        switch command {
        case .clear:
            write(ANSI.clearScreen)
            write(ANSI.cursorHome)
            state.withLock { state in
                state.cursorRow = 0
                state.cursorColumn = 0
            }
            
        case .moveCursor(let row, let column):
            write(ANSI.moveCursor(row: row + 1, column: column + 1))
            state.withLock { state in
                state.cursorRow = row
                state.cursorColumn = column
            }
            
        case .setForeground(let color):
            if let color = color {
                let converted = RendererBase.convertColor(color, capabilities: capabilitiesValue, theme: theme)
                write(converted.toANSI(capabilities: capabilitiesValue, isForeground: true))
                state.withLock { state in
                    state.currentForeground = converted
                }
            } else {
                write(ANSI.resetForeground)
                state.withLock { state in
                    state.currentForeground = nil
                }
            }
            
        case .setBackground(let color):
            if let color = color {
                let converted = RendererBase.convertColor(color, capabilities: capabilitiesValue, theme: theme)
                write(converted.toANSI(capabilities: capabilitiesValue, isForeground: false))
                state.withLock { state in
                    state.currentBackground = converted
                }
            } else {
                write(ANSI.resetBackground)
                state.withLock { state in
                    state.currentBackground = nil
                }
            }
            
        case .setStyle(let style):

            let (currentStyle, currentFg, currentBg) = state.withLock { state in
                (state.currentStyle, state.currentForeground, state.currentBackground)
            }
            
            if currentStyle != .none {
                write(ANSI.reset)

                if let fg = currentFg {
                    write(fg.toANSI(capabilities: capabilitiesValue, isForeground: true))
                }
                if let bg = currentBg {
                    write(bg.toANSI(capabilities: capabilitiesValue, isForeground: false))
                }
            }
            

            if style.contains(.bold) { write(ANSI.bold) }
            if style.contains(.dim) { write(ANSI.dim) }
            if style.contains(.italic) { write(ANSI.italic) }
            if style.contains(.underline) { write(ANSI.underline) }
            if style.contains(.blink) { write(ANSI.blink) }
            if style.contains(.reverse) { write(ANSI.reverse) }
            if style.contains(.hidden) { write(ANSI.hidden) }
            if style.contains(.strikethrough) { write(ANSI.strikethrough) }
            
            state.withLock { state in
                state.currentStyle = style
            }
            
        case .reset:
            write(ANSI.reset)
            state.withLock { state in
                state.currentForeground = nil
                state.currentBackground = nil
                state.currentStyle = .none
            }
            
        case .write(let text):
            write(text)

            state.withLock { state in
                state.cursorColumn += text.count
            }
            
        case .writeLine(let text):
            write(text)
            write("\n")
            state.withLock { state in
                state.cursorRow += 1
                state.cursorColumn = 0
            }
            
        case .clearLine:
            write(ANSI.clearLine)
            state.withLock { state in
                state.cursorColumn = 0
            }
            
        case .clearToEndOfLine:
            write(ANSI.clearToEndOfLine)
            
        case .saveCursor:
            write(ANSI.saveCursor)
            state.withLock { state in
                state.savedRow = state.cursorRow
                state.savedColumn = state.cursorColumn
            }
            
        case .restoreCursor:
            write(ANSI.restoreCursor)
            state.withLock { state in
                state.cursorRow = state.savedRow
                state.cursorColumn = state.savedColumn
            }
            
        case .hideCursor:
            write(ANSI.hideCursor)
            
        case .showCursor:
            write(ANSI.showCursor)
            
        case .flush:
            try await flush()
            
        case .begin, .setText, .frame, .end:

            break
        }
    }
    
    private func write(_ string: String) {
        buffer.withLock { buffer in
            buffer.append(string)
            

            if buffer.count > self.bufferSize {
                self.flushBuffer(&buffer)
            }
        }
    }
    
    private func flushBuffer(_ buffer: inout String) {
        if !buffer.isEmpty {
            if let data = buffer.data(using: .utf8) {
                output.write(data)
            }
            buffer.removeAll(keepingCapacity: true)
        }
    }
    
    public func flush() async throws {
        buffer.withLock { buffer in
            flushBuffer(&buffer)
        }

        if output != .standardOutput && output != .standardError {
            output.synchronizeFile()
        }
    }
    
    public func reset() async throws {
        write(ANSI.reset)
        write(ANSI.clearScreen)
        write(ANSI.cursorHome)
        write(ANSI.showCursor)
        try await flush()
        
        state.withLock { state in
            state.currentForeground = nil
            state.currentBackground = nil
            state.currentStyle = .none
            state.cursorRow = 0
            state.cursorColumn = 0
        }
    }
    
    public func capabilities() -> Capabilities {
        capabilitiesValue
    }
}

private enum ANSI {

    static let cursorHome = "\u{001B}[H"
    static let saveCursor = "\u{001B}7"
    static let restoreCursor = "\u{001B}8"
    static let hideCursor = "\u{001B}[?25l"
    static let showCursor = "\u{001B}[?25h"
    
    static func moveCursor(row: Int, column: Int) -> String {
        "\u{001B}[\(row);\(column)H"
    }
    

    static let clearScreen = "\u{001B}[2J"
    static let clearLine = "\u{001B}[2K"
    static let clearToEndOfLine = "\u{001B}[K"
    static let clearToEndOfScreen = "\u{001B}[J"
    

    static let reset = "\u{001B}[0m"
    static let bold = "\u{001B}[1m"
    static let dim = "\u{001B}[2m"
    static let italic = "\u{001B}[3m"
    static let underline = "\u{001B}[4m"
    static let blink = "\u{001B}[5m"
    static let reverse = "\u{001B}[7m"
    static let hidden = "\u{001B}[8m"
    static let strikethrough = "\u{001B}[9m"
    

    static let resetForeground = "\u{001B}[39m"
    static let resetBackground = "\u{001B}[49m"
}