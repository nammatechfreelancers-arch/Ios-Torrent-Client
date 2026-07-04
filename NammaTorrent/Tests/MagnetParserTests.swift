// MagnetParserTests.swift
import Testing
@testable import NammaTorrent

@Suite("MagnetParser")
struct MagnetParserTests {

    let validMagnet = "magnet:?xt=urn:btih:dd8255ecdc7ca55fb0bbf81323d87062db1f6d1c&dn=Test+Torrent&tr=udp%3A%2F%2Ftracker.example.com%3A6969"

    @Test func parsesInfoHash() throws {
        let info = try MagnetParser.parse(validMagnet)
        #expect(info.infoHash == "dd8255ecdc7ca55fb0bbf81323d87062db1f6d1c")
    }

    @Test func parsesDisplayName() throws {
        let info = try MagnetParser.parse(validMagnet)
        #expect(info.displayName == "Test Torrent")
    }

    @Test func parsesTracker() throws {
        let info = try MagnetParser.parse(validMagnet)
        #expect(info.trackers.contains("udp://tracker.example.com:6969"))
    }

    @Test func infoHashDataLength() throws {
        let info = try MagnetParser.parse(validMagnet)
        #expect(info.infoHashData.count == 20)
    }

    @Test func invalidSchemeThrows() {
        #expect(throws: MagnetParserError.self) {
            try MagnetParser.parse("http://example.com")
        }
    }

    @Test func missingInfoHashThrows() {
        #expect(throws: MagnetParserError.self) {
            try MagnetParser.parse("magnet:?dn=NoHash")
        }
    }

    @Test func multipleTrackers() throws {
        let magnet = "magnet:?xt=urn:btih:dd8255ecdc7ca55fb0bbf81323d87062db1f6d1c&tr=udp://a.com:6969&tr=udp://b.com:6969"
        let info = try MagnetParser.parse(magnet)
        #expect(info.trackers.count == 2)
    }

    @Test func hexDataRoundtrip() {
        let hex = "dd8255ecdc7ca55fb0bbf81323d87062db1f6d1c"
        let data = Data(hexString: hex)
        #expect(data != nil)
        #expect(data?.hexString == hex)
    }
}
