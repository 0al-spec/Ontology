import SpecificationCore

public struct ProtocolConformanceContext: Equatable, Sendable {
    public let protocolRequiredRelations: [String]
    public let classRelationDomains: Set<String>

    public init(protocolRequiredRelations: [String], classRelationDomains: Set<String>) {
        self.protocolRequiredRelations = protocolRequiredRelations
        self.classRelationDomains = classRelationDomains
    }
}

public struct ProtocolRelationConformanceSpec: Specification {
    public typealias T = ProtocolConformanceContext

    public init() {}

    public func isSatisfiedBy(_ candidate: ProtocolConformanceContext) -> Bool {
        candidate.protocolRequiredRelations.allSatisfy { candidate.classRelationDomains.contains($0) }
    }
}
