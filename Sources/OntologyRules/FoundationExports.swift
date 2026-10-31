/// A reference slot determines which kind of imported symbol it can accept.
public enum OntologyReferenceRole: Sendable {
    case classType, protocolType, policyBase
}

/// The compiler-owned, offline export surface of the terminal foundation vocabulary.
public struct FoundationExports: Encodable, Sendable {
    public static let version010 = FoundationExports()
    public let schemaVersion: Int
    public let id: String
    public let version: String
    public let namespace: String
    public let classes: [String]
    public let protocols: [String]
    public let policyBases: [String]

    private init() {
        schemaVersion = 1
        id = "specgraph.foundation"
        version = "0.1.0"
        namespace = "sg"
        classes = ["Actor", "Capability", "Command", "DomainEntity", "Event", "Invariant", "Policy", "StateMachine", "SystemActor", "ValueObject"]
        protocols = ["Approvable", "Auditable", "DeviceBound", "RestrictableCapability", "Signable", "TimeBound", "Versioned"]
        policyBases = ["Policy"]
    }

    public func names(for role: OntologyReferenceRole) -> Set<String> {
        switch role {
        case .classType: Set(classes)
        case .protocolType: Set(protocols)
        case .policyBase: Set(policyBases)
        }
    }
}
