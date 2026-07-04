// BEncodingTests.swift
import Testing
@testable import NammaTorrent

@Suite("BEncoding")
struct BEncodingTests {

    @Test func decodeInteger() throws {
        let data = "i42e".data(using: .utf8)!
        let value = try BDecoder.decode(data)
        #expect(value.intValue == 42)
    }

    @Test func decodeNegativeInteger() throws {
        let data = "i-7e".data(using: .utf8)!
        #expect(try BDecoder.decode(data).intValue == -7)
    }

    @Test func decodeString() throws {
        let data = "4:spam".data(using: .utf8)!
        #expect(try BDecoder.decode(data).stringValue == "spam")
    }

    @Test func decodeList() throws {
        let data = "l4:spami42ee".data(using: .utf8)!
        let list = try BDecoder.decode(data).listValue
        #expect(list?.count == 2)
        #expect(list?[0].stringValue == "spam")
        #expect(list?[1].intValue == 42)
    }

    @Test func decodeDictionary() throws {
        let data = "d3:bar4:spam3:fooi42ee".data(using: .utf8)!
        let dict = try BDecoder.decode(data).dictValue
        #expect(dict?["bar"]?.stringValue == "spam")
        #expect(dict?["foo"]?.intValue == 42)
    }

    @Test func encodeRoundtrip() throws {
        let original: BValue = .dictionary([
            "name": .string("test".data(using: .utf8)!),
            "size": .integer(1024),
            "files": .list([.string("a.txt".data(using: .utf8)!)])
        ])
        let encoded = BEncoder.encode(original)
        let decoded = try BDecoder.decode(encoded)
        #expect(decoded == original)
    }

    @Test func decodeEmptyString() throws {
        let data = "0:".data(using: .utf8)!
        #expect(try BDecoder.decode(data).stringValue == "")
    }

    @Test func decodeNestedDict() throws {
        let data = "d4:infod4:name4:testee".data(using: .utf8)!
        let outer = try BDecoder.decode(data).dictValue
        #expect(outer?["info"]?.dictValue?["name"]?.stringValue == "test")
    }

    @Test func invalidByteThrows() {
        let data = "x42e".data(using: .utf8)!
        #expect(throws: BError.self) { try BDecoder.decode(data) }
    }
}
