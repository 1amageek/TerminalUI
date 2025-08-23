import Foundation
#if os(macOS) || os(Linux)
import Darwin.C
import Darwin

public actor TTYManager {
    private let input: FileHandle
    private let output: FileHandle
    private var originalTermios: termios?
    private var isRawMode = false
    

    public static let shared = TTYManager()
    

    public init(
        input: FileHandle = .standardInput,
        output: FileHandle = .standardOutput
    ) {
        self.input = input
        self.output = output
    }
    
    deinit {

        if isRawMode {
            Task { [weak self] in
                try? await self?.disableRawMode()
            }
        }
    }
    

    

    public func enableRawMode() throws {
        guard !isRawMode else { return }
        
        #if os(macOS) || os(Linux)

        var termios = Darwin.termios()
        if tcgetattr(input.fileDescriptor, &termios) != 0 {
            throw TTYError.failedToGetAttributes
        }
        originalTermios = termios
        

        termios.c_lflag &= ~(UInt(ECHO | ICANON | ISIG | IEXTEN))

        termios.c_iflag &= ~(UInt(IXON | ICRNL | BRKINT | INPCK | ISTRIP))

        termios.c_cflag |= UInt(CS8)

        termios.c_oflag &= ~UInt(OPOST)
        

        withUnsafeMutableBytes(of: &termios.c_cc) { bytes in
            let ccArray = bytes.bindMemory(to: cc_t.self)
            ccArray[Int(VMIN)] = 1
            ccArray[Int(VTIME)] = 0
        }
        

        if tcsetattr(input.fileDescriptor, TCSAFLUSH, &termios) != 0 {
            throw TTYError.failedToSetAttributes
        }
        
        isRawMode = true
        #else

        throw TTYError.rawModeNotSupported
        #endif
    }
    

    public func disableRawMode() throws {
        guard isRawMode else { return }
        
        #if os(macOS) || os(Linux)
        guard var original = originalTermios else {
            throw TTYError.originalSettingsNotSaved
        }
        
        if tcsetattr(input.fileDescriptor, TCSAFLUSH, &original) != 0 {
            throw TTYError.failedToSetAttributes
        }
        
        isRawMode = false
        originalTermios = nil
        #endif
    }
    

    

    public func getTerminalSize() -> (width: Int, height: Int) {
        #if os(macOS) || os(Linux)
        var w = winsize()
        if ioctl(output.fileDescriptor, TIOCGWINSZ, &w) == 0 {
            return (width: Int(w.ws_col), height: Int(w.ws_row))
        }
        #endif
        return (width: 80, height: 24)
    }
    

    public func isTTY() -> Bool {
        return isatty(output.fileDescriptor) != 0
    }
    

    

    public func readInput(timeout: TimeInterval = 0.1) throws -> Data? {
        #if os(macOS) || os(Linux)

        var readSet = fd_set()
        FD_ZERO(&readSet)
        FD_SET(input.fileDescriptor, &readSet)
        
        var timeout = timeval(
            tv_sec: Int(timeout),
            tv_usec: Int32((timeout.truncatingRemainder(dividingBy: 1.0)) * 1_000_000)
        )
        
        let result = select(input.fileDescriptor + 1, &readSet, nil, nil, &timeout)
        
        if result < 0 {
            throw TTYError.selectFailed
        } else if result == 0 {
            return nil
        }
        

        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1024)
        defer { buffer.deallocate() }
        
        let bytesRead = read(input.fileDescriptor, buffer, 1024)
        if bytesRead < 0 {
            throw TTYError.readFailed
        } else if bytesRead == 0 {
            return nil
        }
        
        return Data(bytes: buffer, count: bytesRead)
        #else

        return Data()
        #endif
    }
    

    public func writeOutput(_ data: Data) throws {
        #if os(macOS) || os(Linux)
        let result = data.withUnsafeBytes { bytes in
            system_write(output.fileDescriptor, bytes.baseAddress, data.count)
        }
        
        if result < 0 {
            throw TTYError.writeFailed
        }
        #endif
    }
    

    public func flush() throws {
        #if os(macOS) || os(Linux)
        if fsync(output.fileDescriptor) != 0 {
            throw TTYError.flushFailed
        }
        #endif
    }
}

@globalActor
public actor TTYManagerActor {
    public static let shared = TTYManagerActor()
}

public enum TTYError: Error, Sendable {
    case failedToGetAttributes
    case failedToSetAttributes
    case originalSettingsNotSaved
    case rawModeNotSupported
    case selectFailed
    case readFailed
    case writeFailed
    case flushFailed
    case keyDecodingFailed
    
    public var localizedDescription: String {
        switch self {
        case .failedToGetAttributes:
            return "Failed to get terminal attributes"
        case .failedToSetAttributes:
            return "Failed to set terminal attributes"
        case .originalSettingsNotSaved:
            return "Original terminal settings were not saved"
        case .rawModeNotSupported:
            return "Raw mode is not supported on this platform"
        case .selectFailed:
            return "Select system call failed"
        case .readFailed:
            return "Failed to read from terminal"
        case .writeFailed:
            return "Failed to write to terminal"
        case .flushFailed:
            return "Failed to flush terminal output"
        case .keyDecodingFailed:
            return "Failed to decode key sequence"
        }
    }
}

#if os(macOS) || os(Linux)

private func FD_ZERO(_ set: inout fd_set) {
    set.fds_bits = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
}

private func FD_SET(_ fd: Int32, _ set: inout fd_set) {
    let intOffset = Int(fd / 32)
    let bitOffset = fd % 32
    let mask: Int32 = 1 << bitOffset
    
    withUnsafeMutableBytes(of: &set.fds_bits) { bytes in
        let intArray = bytes.bindMemory(to: Int32.self)
        intArray[intOffset] |= mask
    }
}

private func system_write(_ fd: Int32, _ buffer: UnsafeRawPointer?, _ count: Int) -> Int {
    return Darwin.write(fd, buffer, count)
}
#endif

public extension TTYManager {

    func write(_ string: String) async throws {
        guard let data = string.data(using: .utf8) else {
            throw TTYError.writeFailed
        }
        try writeOutput(data)
    }
    

    func writeLine(_ string: String = "") async throws {
        try await write(string + "\n")
    }
    

    func clearScreen() async throws {
        try await write("\u{001B}[2J\u{001B}[H")
    }
    

    func moveCursor(row: Int, column: Int) async throws {
        try await write("\u{001B}[\(row);\(column)H")
    }
    

    func hideCursor() async throws {
        try await write("\u{001B}[?25l")
    }
    

    func showCursor() async throws {
        try await write("\u{001B}[?25h")
    }
}

#endif