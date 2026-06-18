/// Boolean predicate specification used by OntologyRules validation checks.
public protocol Specification {
    associatedtype T

    func isSatisfiedBy(_ candidate: T) -> Bool
}

/// Multi-outcome decision specification used by OntologyRules classifiers.
public protocol DecisionSpec {
    associatedtype Context
    associatedtype Result

    func decide(_ context: Context) -> Result?
}

/// Closure-backed specification adapter for call sites that need a lightweight predicate wrapper.
public struct PredicateSpec<T>: Specification {
    private let predicate: (T) -> Bool

    public init(_ predicate: @escaping (T) -> Bool) {
        self.predicate = predicate
    }

    public func isSatisfiedBy(_ candidate: T) -> Bool {
        predicate(candidate)
    }
}

/// Type-erased specification wrapper.
public struct AnySpecification<T>: Specification {
    private let evaluator: (T) -> Bool

    public init<S: Specification>(_ specification: S) where S.T == T {
        evaluator = specification.isSatisfiedBy
    }

    public init(_ predicate: @escaping (T) -> Bool) {
        evaluator = predicate
    }

    public func isSatisfiedBy(_ candidate: T) -> Bool {
        evaluator(candidate)
    }
}
