import Foundation
import SpecificationCore

/// Validates ontology symbol names used by classes, relations, policies, protocols, and state machines.
public struct OntologySymbolNameSpec: Specification {
    public typealias T = OntologySymbolName

    public init() {}

    public func isSatisfiedBy(_ candidate: OntologySymbolName) -> Bool {
        matches(candidate.rawValue, #"^[A-Za-z][A-Za-z0-9_]*$"#)
    }
}

/// Validates lower-snake-case state names used inside ontology state machines.
public struct OntologyStateNameSpec: Specification {
    public typealias T = OntologyStateName

    public init() {}

    public func isSatisfiedBy(_ candidate: OntologyStateName) -> Bool {
        matches(candidate.rawValue, #"^[a-z][a-z0-9_]*$"#)
    }
}

/// Validates local or namespace-qualified ontology concept reference literals.
public struct OntologyConceptRefPatternSpec: Specification {
    public typealias T = OntologyConceptReferenceLiteral

    public init() {}

    public func isSatisfiedBy(_ candidate: OntologyConceptReferenceLiteral) -> Bool {
        matches(candidate.rawValue, #"^([A-Za-z][A-Za-z0-9_]*|[A-Za-z][A-Za-z0-9_.-]*:[A-Za-z][A-Za-z0-9_]*)$"#)
    }
}

/// Validates globally scoped ontology package identifiers.
public struct OntologyIdPatternSpec: Specification {
    public typealias T = OntologyPackageId

    public init() {}

    public func isSatisfiedBy(_ candidate: OntologyPackageId) -> Bool {
        matches(candidate.rawValue, #"^[a-z][a-z0-9]*(\.[a-z0-9][a-z0-9-]*)+$"#)
    }
}

/// Validates package-local ontology namespaces.
public struct OntologyNamespacePatternSpec: Specification {
    public typealias T = OntologyNamespace

    public init() {}

    public func isSatisfiedBy(_ candidate: OntologyNamespace) -> Bool {
        matches(candidate.rawValue, #"^[a-z][a-z0-9-]*$"#)
    }
}

/// Validates semantic version literals accepted by ontology package metadata.
public struct OntologySemVerPatternSpec: Specification {
    public typealias T = OntologySemanticVersion

    public init() {}

    public func isSatisfiedBy(_ candidate: OntologySemanticVersion) -> Bool {
        matches(candidate.rawValue, #"^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)([-+][0-9A-Za-z.-]+)?$"#)
    }
}

func matches(_ value: String, _ pattern: String, caseInsensitive: Bool = false) -> Bool {
    var options: String.CompareOptions = [.regularExpression]
    if caseInsensitive {
        options.insert(.caseInsensitive)
    }
    return value.range(of: pattern, options: options) != nil
}
