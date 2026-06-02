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
