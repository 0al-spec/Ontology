import Foundation

/// Foundation's JSON reader accepts repeated object keys. Reject them before use,
/// including differently escaped spellings of the same key.
struct InstanceJSONKeyCheck {
    let bytes: [UInt8]
    var offset = 0

    mutating func validate() throws { try value(depth: 0) }

    mutating func value(depth: Int) throws {
        guard depth < 64 else { throw OntologyCompilerError.invalidArgument("instanceGraph.input.depth: maximum JSON depth is 64") }
        whitespace()
        guard offset < bytes.count else { return }
        switch bytes[offset] {
        case 123: try object(depth: depth + 1)
        case 91:
            offset += 1
            whitespace()
            while offset < bytes.count && bytes[offset] != 93 {
                try value(depth: depth + 1)
                whitespace()
                if offset < bytes.count && bytes[offset] == 44 { offset += 1 }
            }
            offset += 1
        case 34: _ = try string()
        default:
            while offset < bytes.count && ![UInt8(44), 93, 125, 32, 9, 10, 13].contains(bytes[offset]) { offset += 1 }
        }
        whitespace()
    }

    mutating func object(depth: Int) throws {
        offset += 1
        whitespace()
        var keys = Set<String>()
        while offset < bytes.count && bytes[offset] != 125 {
            let key = try string()
            guard keys.insert(key).inserted else { throw OntologyCompilerError.invalidArgument("instanceGraph.input.duplicateKey: \(key)") }
            whitespace()
            offset += 1 // colon; JSONSerialization has already checked syntax.
            try value(depth: depth)
            whitespace()
            if offset < bytes.count && bytes[offset] == 44 { offset += 1; whitespace() }
        }
        offset += 1
    }

    mutating func string() throws -> String {
        let start = offset
        offset += 1
        while offset < bytes.count {
            if bytes[offset] == 92 { offset += 2; continue }
            if bytes[offset] == 34 { offset += 1; break }
            offset += 1
        }
        return try JSONSerialization.jsonObject(with: Data(bytes[start ..< min(offset, bytes.count)]), options: .fragmentsAllowed) as? String ?? ""
    }

    mutating func whitespace() {
        while offset < bytes.count && [UInt8(32), 9, 10, 13].contains(bytes[offset]) { offset += 1 }
    }
}
