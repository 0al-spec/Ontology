import SpecificationCore

/// A candidate ancestor and the package-qualified classes already visited.
public struct InheritanceCycleContext {
    public let candidate: String
    public let visited: Set<String>

    public init(candidate: String, visited: Set<String>) {
        self.candidate = candidate
        self.visited = visited
    }
}

/// A valid ancestry traversal cannot revisit a package-qualified class.
public struct AcyclicInheritanceSpec: Specification {
    public typealias T = InheritanceCycleContext
    public init() {}
    public func isSatisfiedBy(_ candidate: T) -> Bool {
        !candidate.visited.contains(candidate.candidate)
    }
}

/// The instance-level contract of a field, including a resolved reference target.
public struct InheritedFieldSignature: Equatable {
    public let type: String?
    public let required: Bool
    public let target: String?

    public init(type: String?, required: Bool, target: String?) {
        self.type = type
        self.required = required
        self.target = target
    }
}

/// A repeated inherited field must have the same instance-level contract.
public struct CompatibleInheritedFieldSpec: Specification {
    public typealias T = (InheritedFieldSignature, InheritedFieldSignature)
    public init() {}
    public func isSatisfiedBy(_ candidate: T) -> Bool {
        candidate.0 == candidate.1
    }
}

/// A runtime reference target and all supplied package URIs sharing its type name.
public struct RuntimeReferenceIdentityContext {
    public let expectedURI: String
    public let candidateURIs: Set<String>

    public init(expectedURI: String, candidateURIs: Set<String>) {
        self.expectedURI = expectedURI
        self.candidateURIs = candidateURIs
    }
}

/// One runtime reference type must not denote different supplied package classes.
public struct UnambiguousRuntimeReferenceSpec: Specification {
    public typealias T = RuntimeReferenceIdentityContext
    public init() {}
    public func isSatisfiedBy(_ candidate: T) -> Bool {
        candidate.candidateURIs == [candidate.expectedURI]
    }
}
