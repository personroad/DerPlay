import Foundation

/// Bounded DER reader for the two supported standard identity containers.
/// No indefinite lengths, high-tag-number forms or trailing bytes.
enum DerPlayIdentityDER {
    struct Invalid: Error {}
    struct Node {
        let tag: UInt8
        let body: Data
        let encoded: Data
        func children() throws -> [Node] {
            let bytes = Array(body)
            var offset = 0
            var result: [Node] = []
            while offset < body.count {
                guard result.count < 1024 else { throw Invalid() }
                result.append(try DerPlayIdentityDER.read(bytes, &offset))
            }
            return result
        }
    }
    static func read(_ bytes: [UInt8], _ offset: inout Int) throws -> Node {
        let start = offset
        guard offset + 2 <= bytes.count else { throw Invalid() }
        let tag = bytes[offset]; offset += 1
        guard tag & 31 != 31 else { throw Invalid() }
        let first = bytes[offset]; offset += 1
        var length = Int(first)
        if first & 128 != 0 {
            let count = Int(first & 127)
            guard (1...3).contains(count), offset + count <= bytes.count, bytes[offset] != 0 else { throw Invalid() }
            length = 0
            for _ in 0..<count { length = (length << 8) | Int(bytes[offset]); offset += 1 }
            guard length >= 128 else { throw Invalid() }
        }
        guard length <= bytes.count - offset else { throw Invalid() }
        let end = offset + length
        let node = Node(tag: tag, body: Data(bytes[offset..<end]), encoded: Data(bytes[start..<end]))
        offset = end
        return node
    }
    static func root(_ data: Data, tag: UInt8 = 0x30) throws -> Node {
        guard !data.isEmpty, data.count <= 65_536 else { throw Invalid() }
        var offset = 0
        let node = try read(Array(data), &offset)
        guard node.tag == tag, offset == data.count else { throw Invalid() }
        return node
    }
    static func oid(_ node: Node, _ bytes: [UInt8]) -> Bool { node.tag == 0x06 && node.body == Data(bytes) }
    static func certificates(_ data: Data) throws -> [Data] {
        let outer = try root(data).children()
        guard outer.count == 2, oid(outer[0], [0x2a,0x86,0x48,0x86,0xf7,0x0d,0x01,0x07,0x02]), outer[1].tag == 0xa0 else { throw Invalid() }
        let wrapped = try outer[1].children()
        guard wrapped.count == 1, wrapped[0].tag == 0x30 else { throw Invalid() }
        let fields = try wrapped[0].children()
        guard fields.count >= 5, fields[0].tag == 2, fields[1].tag == 0x31, fields[2].tag == 0x30, fields[3].tag == 0xa0, fields.last?.tag == 0x31 else { throw Invalid() }
        let certs = try fields[3].children()
        guard !certs.isEmpty, certs.count <= 64, certs.allSatisfy({ $0.tag == 0x30 }) else { throw Invalid() }
        return certs.map(\.encoded)
    }
    static func pkcs8(_ data: Data) throws -> (scalar: Data, publicPoint: Data?) {
        let fields = try root(data).children()
        guard (3...4).contains(fields.count), fields[0].tag == 2, fields[0].body == Data([0]), fields[1].tag == 0x30, fields[2].tag == 4 else { throw Invalid() }
        if fields.count == 4 { guard fields[3].tag == 0xa0 else { throw Invalid() } }
        let algorithm = try fields[1].children()
        guard algorithm.count == 2,
              oid(algorithm[0], [0x2a,0x86,0x48,0xce,0x3d,0x02,0x01]),
              oid(algorithm[1], [0x2a,0x86,0x48,0xce,0x3d,0x03,0x01,0x07]) else { throw Invalid() }
        let ec = try root(fields[2].body).children()
        guard (2...4).contains(ec.count), ec[0].tag == 2, ec[0].body == Data([1]), ec[1].tag == 4, ec[1].body.count == 32 else { throw Invalid() }
        // If optional SEC1 parameters are present, they must agree with PKCS#8.
        var publicPoint: Data?
        var lastTag: UInt8 = 0x9f
        for field in ec.dropFirst(2) {
            guard field.tag > lastTag else { throw Invalid() }; lastTag = field.tag
            if field.tag == 0xa0 {
                let values = try field.children()
                guard values.count == 1, oid(values[0], [0x2a,0x86,0x48,0xce,0x3d,0x03,0x01,0x07]) else { throw Invalid() }
            } else if field.tag == 0xa1 {
                let values = try field.children()
                guard values.count == 1, values[0].tag == 3, values[0].body.first == 0,
                      values[0].body.count == 66 || values[0].body.count == 34 else { throw Invalid() }
                publicPoint = Data(values[0].body.dropFirst())
            } else { throw Invalid() }
        }
        return (ec[1].body, publicPoint)
    }
}
