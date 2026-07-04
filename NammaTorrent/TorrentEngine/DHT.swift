// DHT.swift — Kademlia DHT node for peer discovery
import Foundation
import Network

public struct DHTNodeInfo: Sendable {
    public let id: Data
    public let ip: String
    public let port: Int
}

public actor DHTNode {
    private let nodeID: Data
    private let port: Int
    private var routingTable: [DHTNodeInfo] = []
    private var isRunning = false
    public var onPeersFound: (([TorrentPeer]) -> Void)?

    private let bootstrapNodes: [(host: String, port: Int)] = [
        ("router.bittorrent.com", 6881),
        ("router.utorrent.com", 6881),
        ("dht.transmissionbt.com", 6881)
    ]

    public init(port: Int = 6881) {
        var id = Data(count: 20)
        id.withUnsafeMutableBytes { _ = SecRandomCopyBytes(kSecRandomDefault, 20, $0.baseAddress!) }
        self.nodeID = id
        self.port = port
    }

    public func start() async {
        guard !isRunning else { return }
        isRunning = true
        for node in bootstrapNodes {
            await sendFindNode(host: node.host, port: node.port, target: nodeID)
        }
    }

    public func stop() { isRunning = false }

    public func getPeers(infoHash: Data) async {
        let closest = closestNodes(to: infoHash, count: 8)
        for node in closest { await sendGetPeers(to: node, infoHash: infoHash) }
    }

    public func addNode(_ node: DHTNodeInfo) {
        guard !routingTable.contains(where: { $0.id == node.id }) else { return }
        routingTable.append(node)
        if routingTable.count > 1000 { routingTable.removeFirst() }
    }

    private func sendFindNode(host: String, port: Int, target: Data) async {
        let msg: BValue = .dictionary([
            "t": .string(randomTxID()),
            "y": .string("q".data(using: .utf8)!),
            "q": .string("find_node".data(using: .utf8)!),
            "a": .dictionary(["id": .string(nodeID), "target": .string(target)])
        ])
        await udpSend(BEncoder.encode(msg), host: host, port: port)
    }

    private func sendGetPeers(to node: DHTNodeInfo, infoHash: Data) async {
        let msg: BValue = .dictionary([
            "t": .string(randomTxID()),
            "y": .string("q".data(using: .utf8)!),
            "q": .string("get_peers".data(using: .utf8)!),
            "a": .dictionary(["id": .string(nodeID), "info_hash": .string(infoHash)])
        ])
        await udpSend(BEncoder.encode(msg), host: node.ip, port: node.port)
    }

    private func udpSend(_ data: Data, host: String, port: Int) async {
        let ep = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(integerLiteral: UInt16(port))
        )
        let conn = NWConnection(to: ep, using: .udp)
        conn.send(content: data, completion: .idempotent)
        conn.start(queue: .global(qos: .background))
        try? await Task.sleep(nanoseconds: 200_000_000)
        conn.cancel()
    }

    private func closestNodes(to target: Data, count: Int) -> [DHTNodeInfo] {
        routingTable
            .sorted { self.xor($0.id, target).lexicographicallyPrecedes(self.xor($1.id, target)) }
            .prefix(count).map { $0 }
    }

    private func xor(_ a: Data, _ b: Data) -> Data {
        Data(zip(a.prefix(20), b.prefix(20)).map { $0 ^ $1 })
    }

    private func randomTxID() -> Data {
        Data([UInt8.random(in: 0...255), UInt8.random(in: 0...255)])
    }
}
