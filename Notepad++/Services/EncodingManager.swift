//
//  EncodingManager.swift
//  Notepad++
//
//  Created for encoding detection and management
//  Direct port of Notepad++ encoding detection logic
//

import Foundation

// Match Notepad++ EolType enum exactly
enum EOLType: Int, CaseIterable {
    case windows = 0  // CRLF (\r\n)
    case macos = 1    // CR (\r) - Old Mac
    case unix = 2     // LF (\n)
    
    var displayName: String {
        switch self {
        case .windows:
            return "Windows (CRLF)"
        case .macos:
            return "Mac (CR)"
        case .unix:
            return "Unix (LF)"
        }
    }
    
    var shortName: String {
        switch self {
        case .windows:
            return "CRLF"
        case .macos:
            return "CR"
        case .unix:
            return "LF"
        }
    }
    
    var characters: String {
        switch self {
        case .windows:
            return "\r\n"
        case .macos:
            return "\r"
        case .unix:
            return "\n"
        }
    }
    
    static var osDefault: EOLType {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        return .unix
        #else
        return .windows
        #endif
    }
}

// Match Notepad++ UniMode enum exactly
enum FileEncoding: Int, CaseIterable {
    case ansi = 0           // uni8Bit - ANSI/Windows-1252
    case utf8BOM = 1        // uniUTF8 - UTF-8 with BOM
    case utf16BEBOM = 2     // uni16BE - UTF-16 Big Endian with BOM
    case utf16LEBOM = 3     // uni16LE - UTF-16 Little Endian with BOM
    case utf8 = 4           // uniCookie - UTF-8 without BOM
    case ascii = 5          // uni7Bit - Pure ASCII
    case utf16BE = 6        // uni16BE_NoBOM - UTF-16 Big Endian without BOM
    case utf16LE = 7        // uni16LE_NoBOM - UTF-16 Little Endian without BOM
    
    var displayName: String {
        switch self {
        case .ansi:
            return "ANSI"
        case .utf8BOM:
            return "UTF-8-BOM"
        case .utf16BEBOM:
            return "UCS-2 BE BOM"
        case .utf16LEBOM:
            return "UCS-2 LE BOM"
        case .utf8:
            return "UTF-8"
        case .ascii:
            return "ASCII"
        case .utf16BE:
            return "UCS-2 BE"
        case .utf16LE:
            return "UCS-2 LE"
        }
    }
    
    var stringEncoding: String.Encoding {
        switch self {
        case .ansi:
            return .windowsCP1252
        case .utf8BOM, .utf8:
            return .utf8
        case .utf16BEBOM, .utf16BE:
            return .utf16BigEndian
        case .utf16LEBOM, .utf16LE:
            return .utf16LittleEndian
        case .ascii:
            return .ascii
        }
    }
    
    var hasBOM: Bool {
        switch self {
        case .utf8BOM, .utf16BEBOM, .utf16LEBOM:
            return true
        default:
            return false
        }
    }
}

// BOM (Byte Order Mark) definitions
struct BOM {
    static let utf8: [UInt8] = [0xEF, 0xBB, 0xBF]
    static let utf16BE: [UInt8] = [0xFE, 0xFF]
    static let utf16LE: [UInt8] = [0xFF, 0xFE]
    static let utf32BE: [UInt8] = [0x00, 0x00, 0xFE, 0xFF]
    static let utf32LE: [UInt8] = [0xFF, 0xFE, 0x00, 0x00]
}

@MainActor
class EncodingManager {
    static let shared = EncodingManager()
    
    private init() {}
    
    // Detect encoding from file data (matches Notepad++ logic)
    func detectEncoding(from data: Data) -> FileEncoding {
        // Check for BOM first
        if let bomEncoding = detectBOM(from: data) {
            return bomEncoding
        }
        
        // No BOM found, analyze content
        return analyzeContent(data)
    }
    
    // Detect encoding from file URL
    func detectEncoding(from url: URL) throws -> FileEncoding {
        let data = try Data(contentsOf: url)
        return detectEncoding(from: data)
    }
    
    // Read file with detected encoding and EOL
    func readFile(at url: URL, openAnsiAsUtf8: Bool = true) throws -> (content: String, encoding: FileEncoding, eolType: EOLType) {
        let data = try Data(contentsOf: url)
        var detectedEncoding = detectEncoding(from: data)
        
        // Handle "Open ANSI as UTF-8" setting
        if detectedEncoding == .ansi && openAnsiAsUtf8 {
            // Try to read as UTF-8 first
            if let _ = String(data: data, encoding: .utf8) {
                detectedEncoding = .utf8
            }
        }
        
        // Remove BOM if present
        let contentData: Data
        if detectedEncoding.hasBOM {
            contentData = removeBOM(from: data, encoding: detectedEncoding)
        } else {
            contentData = data
        }
        
        // Convert to string using detected encoding
        let content: String
        if let str = String(data: contentData, encoding: detectedEncoding.stringEncoding) {
            content = str
        } else if detectedEncoding == .ansi,
                  let str = String(data: contentData, encoding: .windowsCP1252) {
            // Fallback for ANSI
            content = str
        } else {
            // Last resort: force UTF-8
            content = String(decoding: contentData, as: UTF8.self)
        }
        
        // Detect EOL type
        let eolType = detectEOL(from: content)
        
        return (content, detectedEncoding, eolType)
    }
    
    // Detect EOL type from content
    func detectEOL(from content: String) -> EOLType {
        // Count occurrences of each EOL type
        var crlfCount = 0
        var lfCount = 0
        var crCount = 0
        
        let nsString = content as NSString
        var searchRange = NSRange(location: 0, length: nsString.length)
        
        // Count CRLF first (must be done before counting individual CR and LF)
        while searchRange.location < nsString.length {
            let range = nsString.range(of: "\r\n", options: [], range: searchRange)
            if range.location != NSNotFound {
                crlfCount += 1
                searchRange.location = range.location + range.length
                searchRange.length = nsString.length - searchRange.location
            } else {
                break
            }
        }
        
        // Count standalone LF (not part of CRLF)
        searchRange = NSRange(location: 0, length: nsString.length)
        while searchRange.location < nsString.length {
            let range = nsString.range(of: "\n", options: [], range: searchRange)
            if range.location != NSNotFound {
                // Check if it's not part of CRLF
                if range.location == 0 || nsString.character(at: range.location - 1) != 13 { // 13 = \r
                    lfCount += 1
                }
                searchRange.location = range.location + 1
                searchRange.length = nsString.length - searchRange.location
            } else {
                break
            }
        }
        
        // Count standalone CR (not part of CRLF)
        searchRange = NSRange(location: 0, length: nsString.length)
        while searchRange.location < nsString.length {
            let range = nsString.range(of: "\r", options: [], range: searchRange)
            if range.location != NSNotFound {
                // Check if it's not part of CRLF
                if range.location + 1 >= nsString.length || nsString.character(at: range.location + 1) != 10 { // 10 = \n
                    crCount += 1
                }
                searchRange.location = range.location + 1
                searchRange.length = nsString.length - searchRange.location
            } else {
                break
            }
        }
        
        // Determine EOL type based on counts
        if crlfCount > 0 && crlfCount >= lfCount && crlfCount >= crCount {
            return .windows
        } else if lfCount > 0 && lfCount >= crCount {
            return .unix
        } else if crCount > 0 {
            return .macos
        } else {
            // No line endings found, use OS default
            return EOLType.osDefault
        }
    }
    
    // Convert EOL type in content
    func convertEOL(in content: String, to eolType: EOLType) -> String {
        // First normalize all line endings to LF
        var normalized = content.replacingOccurrences(of: "\r\n", with: "\n")
        normalized = normalized.replacingOccurrences(of: "\r", with: "\n")
        
        // Then convert to target EOL type
        switch eolType {
        case .windows:
            return normalized.replacingOccurrences(of: "\n", with: "\r\n")
        case .macos:
            return normalized.replacingOccurrences(of: "\n", with: "\r")
        case .unix:
            return normalized
        }
    }
    
    // Write file with specified encoding
    func writeFile(content: String, to url: URL, encoding: FileEncoding) throws {
        var data = Data()
        
        // Add BOM if needed
        if encoding.hasBOM {
            data.append(contentsOf: getBOM(for: encoding))
        }
        
        // Convert string to data with encoding
        if let contentData = content.data(using: encoding.stringEncoding) {
            data.append(contentData)
        } else {
            throw EncodingError.conversionFailed
        }
        
        try data.write(to: url)
    }
    
    // MARK: - Private Methods
    
    private func detectBOM(from data: Data) -> FileEncoding? {
        guard data.count >= 2 else { return nil }
        
        // Check UTF-8 BOM (3 bytes)
        if data.count >= 3 {
            let first3 = Array(data.prefix(3))
            if first3 == BOM.utf8 {
                return .utf8BOM
            }
        }
        
        // Check UTF-32 BOMs (4 bytes) - though not in our enum, check to avoid misdetection
        if data.count >= 4 {
            let first4 = Array(data.prefix(4))
            if first4 == BOM.utf32BE || first4 == BOM.utf32LE {
                // Treat as UTF-16 for now since we don't support UTF-32
                return first4[0] == 0xFF ? .utf16LEBOM : .utf16BEBOM
            }
        }
        
        // Check UTF-16 BOMs (2 bytes)
        let first2 = Array(data.prefix(2))
        if first2 == BOM.utf16BE {
            return .utf16BEBOM
        } else if first2 == BOM.utf16LE {
            return .utf16LEBOM
        }
        
        return nil
    }
    
    private func analyzeContent(_ data: Data) -> FileEncoding {
        guard data.count > 0 else { return .utf8 }
        
        let bytes = Array(data)
        var hasHighBytes = false
        var isValidUtf8 = true
        var i = 0
        
        while i < bytes.count && i < 8192 { // Check first 8KB like Notepad++
            let byte = bytes[i]
            
            // Check for high bytes (non-ASCII)
            if byte > 0x7F {
                hasHighBytes = true
                
                // Validate UTF-8 sequence
                if isValidUtf8 {
                    let sequenceLength = getUtf8SequenceLength(byte)
                    if sequenceLength == 0 {
                        isValidUtf8 = false
                    } else if i + sequenceLength > bytes.count {
                        isValidUtf8 = false
                    } else {
                        // Check continuation bytes
                        for j in 1..<sequenceLength {
                            if (bytes[i + j] & 0xC0) != 0x80 {
                                isValidUtf8 = false
                                break
                            }
                        }
                        i += sequenceLength - 1
                    }
                }
            }
            
            // Check for null bytes (might indicate UTF-16)
            if byte == 0 && i + 1 < bytes.count {
                // Pattern analysis for UTF-16
                if i % 2 == 0 && bytes[i + 1] != 0 {
                    // Possible UTF-16 BE
                    return .utf16BE
                } else if i % 2 == 1 && bytes[i - 1] != 0 {
                    // Possible UTF-16 LE
                    return .utf16LE
                }
            }
            
            i += 1
        }
        
        // Determine encoding based on analysis
        if !hasHighBytes {
            return .ascii // Pure ASCII
        } else if isValidUtf8 {
            return .utf8 // UTF-8 without BOM
        } else {
            return .ansi // ANSI/Windows-1252
        }
    }
    
    private func getUtf8SequenceLength(_ firstByte: UInt8) -> Int {
        if firstByte < 0x80 {
            return 1
        } else if (firstByte & 0xE0) == 0xC0 {
            return 2
        } else if (firstByte & 0xF0) == 0xE0 {
            return 3
        } else if (firstByte & 0xF8) == 0xF0 {
            return 4
        } else {
            return 0 // Invalid UTF-8 start byte
        }
    }
    
    private func removeBOM(from data: Data, encoding: FileEncoding) -> Data {
        switch encoding {
        case .utf8BOM:
            return data.count > 3 ? data.dropFirst(3) : data
        case .utf16BEBOM, .utf16LEBOM:
            return data.count > 2 ? data.dropFirst(2) : data
        default:
            return data
        }
    }
    
    private func getBOM(for encoding: FileEncoding) -> [UInt8] {
        switch encoding {
        case .utf8BOM:
            return BOM.utf8
        case .utf16BEBOM:
            return BOM.utf16BE
        case .utf16LEBOM:
            return BOM.utf16LE
        default:
            return []
        }
    }
}

enum EncodingError: LocalizedError {
    case conversionFailed
    case unsupportedEncoding
    
    var errorDescription: String? {
        switch self {
        case .conversionFailed:
            return "Failed to convert text to the specified encoding"
        case .unsupportedEncoding:
            return "The file uses an unsupported encoding"
        }
    }
}