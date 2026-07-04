// MARK: - BEncoding.swift
// Pure-Swift Bencode encoder/decoder used for .torrent file parsing and tracker responses.

import Foundation

// MARK: - BValue
public indirect enum BValue: Equatable {
    case string(Data)
    case integer(Int64)
    case list([BValue])
    case dictionary([String: BValue])

    public var stringValue: String? {
        guard case .string(let d) = self else { return nil }
        return String(data: d, encoding: .utf8)
    }
    public var dataValue: Data? {
        guard case .string(let d) = self else { return nil }
        return d
    }
    public var intValue: Int64? {
        guard case .integer(let i) = self else { return nil }
        return i
    }
    public var listValue: [BValue]? {
        guard case .list(let l) = self else { return nil }
        return l
    }
    public var dictValue: [String: BValue]? {
        guard case .dictionary(let d) = self else { return nil }
        return d
    }
}

// MARK: - BDecoder
public enum BDecoder {
    public static func decode(_ data: Data) throws -> BValue {
        var index = data.startIndex
        return try parseValue(data: data, index: &index)
    }

    private static func parseValue(data: Data, index: inout Data.Index) throws -> BValue {
        guard index < data.endIndex else { throw BError.unexpectedEnd }
        let byte = data[index]
        switch byte {
        case UInt8(ascii: "i"):
            return try parseInteger(data: data, index: &index)
        case UInt8(ascii: "l"):
            return try parseList(data: data, index: &index)
        case UInt8(ascii: "d"):
            return try parseDict(data: data, index: &index)
        case UInt8(ascii: "0")...UInt8(ascii: "9"):
            return try parseString(data: data, index: &index)
        default:
            throw BError.invalidByte(byte)
        }
    }

    private static func parseInteger(data: Data, index: inout Data.Index) throws -> BValue {
        index = data.index(after: index) // skip 'i'
        guard let eIdx = data[index...].firstIndex(of: UInt8(ascii: "e")) else { throw BError.missingTerminator }
        let numStr = String(data: data[index..<eIdx], encoding: .utf8) ?? ""
        guard let num = Int64(numStr) else { throw BError.invalidInteger(numStr) }
        index = data.index(after: eIdx) // skip 'e'
        return .integer(num)
    }

    private static func parseString(data: Data, index: inout Data.Index) throws -> BValue {
        guard let colonIdx = data[index...].firstIndex(of: UInt8(ascii: ":")) else { throw BError.missingColon }
        let lenStr = String(data: data[index..<colonIdx], encoding: .utf8) ?? ""
        guard let len = Int(lenStr) else { throw BError.invalidLength(lenStr) }
        let start = data.index(after: colonIdx)
        guard let end = data.index(start, offsetBy: len, limitedBy: data.endIndex) else { throw BError.truncated }
        let strData = data[start..<end]
        index = end
        return .string(strData)
    }

    private static func parseList(data: Data, index: inout Data.Index) throws -> BValue {
        index = data.index(after: index) // skip 'l'
        var items: [BValue] = []
        while index < data.endIndex && data[index] != UInt8(ascii: "e") {
            items.append(try parseValue(data: data, index: &index))
        }
        guard index < data.endIndex else { throw BError.missingTerminator }
        index = data.index(after: index) // skip 'e'
        return .list(items)
    }

    private static func parseDict(data: Data, index: inout Data.Index) throws -> BValue {
        index = data.index(after: index) // skip 'd'
        var dict: [String: BValue] = [:]
        while index < data.endIndex && data[index] != UInt8(ascii: "e") {
            guard case .string(let keyData) = try parseString(data: data, index: &index),
                  let key = String(data: keyData, encoding: .utf8) else { throw BError.invalidKey }
            dict[key] = try parseValue(data: data, index: &index)
        }
        guard index < data.endIndex else { throw BError.missingTerminator }
        index = data.index(after: index) // skip 'e'
        return .dictionary(dict)
    }
}

// MARK: - BEncoder
public enum BEncoder {
    public static func encode(_ value: BValue) -> Data {
        var data = Data()
        encode(value, into: &data)
        return data
    }

    private static func encode(_ value: BValue, into data: inout Data) {
        switch value {
        case .integer(let i):
            data.append(contentsOf: "i\(i)e".utf8)
        case .string(let s):
            data.append(contentsOf: "\(s.count):".utf8)
            data.append(s)
        case .list(let l):
            data.append(UInt8(ascii: "l"))
            l.forEach { encode($0, into: &data) }
            data.append(UInt8(ascii: "e"))
        case .dictionary(let d):
            data.append(UInt8(ascii: "d"))
            d.keys.sorted().forEach { key in
                encode(.string(key.data(using: .utf8)!), into: &data)
                encode(d[key]!, into: &data)
            }
            data.append(UInt8(ascii: "e"))
        }
    }
}

// MARK: - BError
public enum BError: Error, LocalizedError {
    case unexpectedEnd
    case invalidByte(UInt8)
    case missingTerminator
    case invalidInteger(String)
    case missingColon
    case invalidLength(String)
    case truncated
    case invalidKey

    public var errorDescription: String? {
        switch self {
        case .unexpectedEnd:         return "Unexpected end of bencode data"
        case .invalidByte(let b):    return "Invalid bencode byte: \(b)"
        case .missingTerminator:     return "Missing 'e' terminator"
        case .invalidInteger(let s): return "Invalid integer: \(s)"
        case .missingColon:          return "Missing ':' in string"
        case .invalidLength(let s):  return "Invalid string length: \(s)"
        case .truncated:             return "Data truncated"
        case .invalidKey:            return "Invalid dictionary key"
        }
    }
}
