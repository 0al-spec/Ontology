import SpecificationCore

public struct RelationEndpointNames: Equatable, Sendable {
    public let subject: String
    public let object: String

    public static let acting = Self(subject: "subject", object: "object")
    public static let binary = Self(subject: "domain", object: "range")
}

/// Each source relation uses one complete spelling. Mixing the two is ambiguous.
public struct RelationEndpointNamesSpec: DecisionSpec {
    public init() {}

    public func decide(_ keys: Set<String>) -> RelationEndpointNames? {
        let usesActingNames = !keys.isDisjoint(with: ["subject", "object"])
        if !keys.isDisjoint(with: ["domain", "range"]) {
            return usesActingNames ? nil : .binary
        }
        return usesActingNames || keys.contains("action") ? .acting : .binary
    }
}
