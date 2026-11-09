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
