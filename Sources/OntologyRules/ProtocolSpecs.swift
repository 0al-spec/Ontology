import SpecificationCore

/// Inputs used to verify that a class supplies all relations required by an implemented protocol.
public struct ProtocolConformanceContext: Equatable, Sendable {
    public let protocolRequiredRelations: [String]
    public let classRelationDomains: Set<String>

    public init(protocolRequiredRelations: [String], classRelationDomains: Set<String>) {
        self.protocolRequiredRelations = protocolRequiredRelations
        self.classRelationDomains = classRelationDomains
    }
}

/// Validates relation-level protocol conformance for one class.
public struct ProtocolRelationConformanceSpec: Specification {
    public typealias T = ProtocolConformanceContext

    public init() {}

    public func isSatisfiedBy(_ candidate: ProtocolConformanceContext) -> Bool {
        candidate.protocolRequiredRelations.allSatisfy { candidate.classRelationDomains.contains($0) }
    }
}

/// `id` is the SDK's built-in optional string identity, which a protocol may require.
public struct ProtocolBuiltinIdentitySpec: Specification {
    public typealias T = OntologyFieldName
    public init() {}
    public func isSatisfiedBy(_ candidate: OntologyFieldName) -> Bool {
        candidate.rawValue == "id"
    }
}

/// Evidence available for one named protocol obligation along a class ancestry.
public struct ProtocolObligationContext {
    public let name: String
    public let declaredNames: Set<String>
    public let ancestryComplete: Bool

    public init(name: String, declaredNames: Set<String>, ancestryComplete: Bool) {
        self.name = name
        self.declaredNames = declaredNames
        self.ancestryComplete = ancestryComplete
    }
}

public enum ProtocolObligationDecision: Equatable {
    case satisfied, missing, unverified
}

/// Missing evidence is a defect only if all relevant ancestry sources are available.
public struct ProtocolObligationDecisionSpec: DecisionSpec {
    public typealias Context = ProtocolObligationContext
    public typealias Result = ProtocolObligationDecision

    public init() {}

    public func decide(_ context: ProtocolObligationContext) -> ProtocolObligationDecision? {
        if context.declaredNames.contains(context.name) { return .satisfied }
        return context.ancestryComplete ? .missing : .unverified
    }
}
