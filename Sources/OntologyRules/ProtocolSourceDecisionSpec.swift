import SpecificationCore

/// An explicitly supplied package and the protocols declared by its source.
public struct ProtocolSourceCandidate {
    public let identity: DiagramPackageIdentity
    public let protocolNames: Set<String>

    public init(identity: DiagramPackageIdentity, protocolNames: Set<String>) {
        self.identity = identity
        self.protocolNames = protocolNames
    }
}

/// The exact package identity selected in the scope of the declaring package.
public struct ProtocolSourceContext {
    public let identity: DiagramPackageIdentity
    public let protocolName: String
    public let candidates: [ProtocolSourceCandidate]

    public init(identity: DiagramPackageIdentity, protocolName: String, candidates: [ProtocolSourceCandidate]) {
        self.identity = identity
        self.protocolName = protocolName
        self.candidates = candidates
    }
}

public enum ProtocolSourceDecision: Equatable {
    case resolved, missingSource, ambiguousSource, missingProtocol
}

/// Selects a protocol only from the single source with the exact imported identity.
public struct ProtocolSourceDecisionSpec: DecisionSpec {
    public typealias Context = ProtocolSourceContext
    public typealias Result = ProtocolSourceDecision

    public init() {}

    public func decide(_ context: ProtocolSourceContext) -> ProtocolSourceDecision? {
        let matches = context.candidates.filter { $0.identity == context.identity }
        guard !matches.isEmpty else { return .missingSource }
        guard matches.count == 1, let match = matches.first else { return .ambiguousSource }
        return match.protocolNames.contains(context.protocolName) ? .resolved : .missingProtocol
    }
}
